# Representation of an oW1 asset (page record)

package Asset;
use Carp;
use strict;
use warnings;
use MongoDB;
use MongoDB::OID;
use boolean;
use JSON -convert_blessed_universally;
use Places qw(EstimateLLfromName);
use String::Approx 'amatch';
use Exporter;
@Asset::ISA    = qw(Exporter);
@Asset::EXPORT = qw(asset_read);

sub new {
    my $that   = shift;
    my $class  = ref($that) || $that;
    my $id     = shift;
    my $db     = shift;
    my $assetI = $db->assets->find( { "_id" => $id } );
    my $self   = $assetI->next;                        # Assume there's only one
    bless $self, $class;
    return $self;
}

sub asset_read {
    my $id   = shift;
    my $db   = shift;
    my $Self = new Asset( $id, $db );
    $Self->read_transcriptions($db);

    # Make a cannonical date
    my %Date;
    foreach my $Transcription ( @{ $Self->{transcriptions} } ) {
        foreach my $Annotation ( @{ $Transcription->{annotations} } ) {
            if ( defined( $Annotation->{data}->{day} ) ) {
                push @{ $Date{day} }, $Annotation->{data}->{day};
            }
            if ( defined( $Annotation->{data}->{month} ) ) {
                push @{ $Date{month} }, $Annotation->{data}->{month};
            }
            if ( defined( $Annotation->{data}->{year} ) ) {
                push @{ $Date{year} }, $Annotation->{data}->{year};
            }
        }
    }
    for my $Variable ( keys(%Date) ) {
        (
            $Self->{CDate}->{data}->{$Variable},
            $Self->{CDate}->{qc}->{$Variable}
        ) = Merge_annotations( @{ $Date{$Variable} } );
    }

    # Make a cannonical location
    my %Positions;
    foreach my $Transcription ( @{ $Self->{transcriptions} } ) {
        foreach my $Annotation ( @{ $Transcription->{annotations} } ) {
            unless (
                   defined( $Annotation->{data}->{lat} )
                || defined( $Annotation->{data}->{port} )
                || ( defined( $Annotation->{data}->{category} )
                    && $Annotation->{data}->{category} eq 'Place' )
              )
            {
                next;
            }
            if ( defined( $Annotation->{data}->{port} )
                && $Annotation->{data}->{port} =~ /\w+/ )
            {
                my $LL = (
                    EstimateLLfromName(
                        $Annotation->{data}->{port},
                        0, 90, 0, 180
                    )
                )[0];
                $Annotation->{data}->{portname} = $LL->[0];
                $Annotation->{data}->{portlon}  = $LL->[1];
                $Annotation->{data}->{portlat}  = $LL->[2];
            }
            if ( defined( $Annotation->{data}->{category} )
                && $Annotation->{data}->{category} eq 'Place' )
            {
                my $LL = (
                    EstimateLLfromName(
                        $Annotation->{data}->{category_value},
                        0, 90, 0, 180
                    )
                )[0];
                $Annotation->{data}->{placename} = $LL->[0];
                $Annotation->{data}->{placelon}  = $LL->[1];
                $Annotation->{data}->{placelat}  = $LL->[2];
            }
            for my $Variable ( keys( %{ $Annotation->{data} } ) ) {
                push @{ $Positions{$Variable} },
                  $Annotation->{data}->{$Variable};
            }
        }
    }
    for my $Variable ( keys(%Positions) ) {
        (
            $Self->{CPosition}->{data}->{$Variable},
            $Self->{CPosition}->{qc}->{$Variable}
        ) = Merge_annotations( @{ $Positions{$Variable} } );
    }
    my @CWeather;
    for ( my $Hour = 1 ; $Hour <= 24 ; $Hour++ ) {
        my %Hourly;
        foreach my $Transcription ( @{ $Self->{transcriptions} } ) {
            foreach my $Annotation ( @{ $Transcription->{annotations} } ) {
                if ( defined( $Annotation->{data}->{Chour} )
                    && $Annotation->{data}->{Chour} == $Hour )
                {
                    for my $Variable ( keys( %{ $Annotation->{data} } ) ) {
                        if ( $Variable =~ /hour/ ) { next; }
                        push @{ $Hourly{$Variable} },
                          $Annotation->{data}->{$Variable};
                    }
                }
            }
        }
        for my $Variable ( keys(%Hourly) ) {
            (
                $Self->{CWeather}[$Hour]->{data}->{$Variable},
                $Self->{CWeather}[$Hour]->{qc}->{$Variable}
            ) = Merge_annotations( @{ $Hourly{$Variable} } );
        }
    }

    return ($Self);
}

sub read_transcriptions {
    my $Asset = shift;
    my $db    = shift;
    $Asset->{transcriptions} = ();
    my $transcriptionI =
      $db->classifications->find( { "asset_ids" => $Asset->{_id} } );

    while ( my $Transcription = $transcriptionI->next ) {

        # Sort annotations by position on the page (top to bottom)
        @{ $Transcription->{annotations} } =
          sort { $a->{page_info}->{top} <=> $b->{page_info}->{top} }
          @{ $Transcription->{annotations} };

        # Count the weather observations (needed to get their times)
        my $NWeather = 0;
        for (
            my $i = 0 ;
            $i < scalar( @{ $Transcription->{annotations} } ) ;
            $i++
          )
        {
            if ( defined( $Transcription->{annotations}[$i]->{data}->{air} ) ) {
                $NWeather++;
            }
        }

        my $Nw = 0;
        for (
            my $i = 0 ;
            $i < scalar( @{ $Transcription->{annotations} } ) ;
            $i++
          )
        {

            if ( defined( $Transcription->{annotations}[$i]->{data}->{air} ) ) {

                # Clean up the inputs
                for my $Variable (
                    keys( %{ $Transcription->{annotations}[$i]->{data} } ) )
                {
                    if ( $Variable =~ /hour/ ) { next; }
                    my $Last;
                    if ( $i > 0 ) {
                        $Last =
                          $Transcription->{annotations}[ $i - 1 ]->{data}
                          ->{$Variable};
                    }
                    $Transcription->{annotations}[$i]->{data}->{$Variable} =
                      CS_weather(
                        $Transcription->{annotations}[$i]->{data}->{$Variable},
                        $Last, $Variable
                      );
                }

                # Add a cannonical hour
                my $Chour = Make_cannonical_hour(
                    $Transcription->{annotations}[$i]->{page_info}->{top},
                    $Nw, $NWeather );
                $Transcription->{annotations}[$i]->{data}->{Chour} = $Chour;

#warn("$Chour $Transcription->{annotations}[$i]->{page_info}->{top} $Nw $NWeather");
                $Nw++;

            }

            if (
                defined( $Transcription->{annotations}[$i]->{data}->{raw_lat} )
              )
            {
                $Transcription->{annotations}[$i]->{data}->{raw_lat} =
                  CS_latitude(
                    $Transcription->{annotations}[$i]->{data}->{raw_lat} );
            }
            if (
                defined( $Transcription->{annotations}[$i]->{data}->{raw_lng} )
              )
            {
                $Transcription->{annotations}[$i]->{data}->{raw_lng} =
                  CS_longitude(
                    $Transcription->{annotations}[$i]->{data}->{raw_lng} );
            }
            if ( defined( $Transcription->{annotations}[$i]->{data}->{port} ) )
            {
                $Transcription->{annotations}[$i]->{data}->{port} =
                  CS_port( $Transcription->{annotations}[$i]->{data}->{port} );

            }
        }

        push @{ $Asset->{transcriptions} }, $Transcription;
    }
}

# Clean and standardise a weather variable
sub CS_weather {
    my $Var   = shift;
    my $Last  = shift;    # cleaned previous observation
    my $Which = shift;
    if ( defined($Last) && $Var =~ /\"|do/ ) { $Var = $Last; }    # Dittos
    if ( $Which eq 'air' ) {
        if ( defined($Last) && $Var =~ /\"|do/ ) { $Var = $Last; }
        $Var =~ s/[^\.\-\d]//g;
        return $Var;
    }
    if ( $Which eq 'bulb' ) {
        $Var =~ s/[^\.\-\d]//g;
        return $Var;
    }
    if ( $Which eq 'B_height' ) {
        $Var =~ s/[^\.\d]//g;
        if ( $Var =~ /^\./ && defined($Last) && $Last =~ /(\d\d)\./ ) {
            $Var = $1 . $Var;
        }
        return $Var;
    }
    if ( $Which eq 'T_height' ) {
        $Var =~ s/[^\-\d]//g;
        return $Var;
    }
    if ( $Which eq 'sea' ) {
        $Var =~ s/\.\D//g;
        return $Var;
    }
    if ( $Which eq 'B_code' ) {
        $Var = lc($Var);
        $Var =~ s/[^a-z]//g;
        return $Var;
    }
    if ( $Which eq 'wind_direction' ) {
        $Var = lc($Var);
        $Var =~ s/[^a-z1-4\/]//g;
        $Var =~ s/by/x/;
        return $Var;
    }
    if ( $Which eq 'wind_force' ) {
        $Var =~ s/[^\.\-\d]//g;
        return $Var;
    }
    die "Unknown weather variable $Which";
}

sub Make_cannonical_hour {
    my $ypx      = shift;
    my $Count    = shift;
    my $NWeather = shift;
    my $Chour;
    if ( $NWeather == 24 ) {    # Hourly obs
        $Chour = (
            1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12,
            13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
        )[$Count];
    }
    elsif ( $NWeather == 6 ) {    # Every watch
        $Chour = ( 4, 8, 12, 16, 20, 24 )[$Count];
    }
    elsif ( $NWeather == 7 ) {    # Every watch and dog watch
        $Chour = ( 4, 8, 12, 16, 18, 20, 24 )[$Count];
    }
    else {                        # Irregular. Guess from ypx based on watches
        if ( $ypx > 800 ) { $Chour = 24; }
        elsif ( $ypx > 700 ) {
            $Chour = 20;
        }
        elsif ( $ypx > 500 ) {
            $Chour = 16;
        }
        elsif ( $ypx > 400 ) {
            $Chour = 12;
        }
        elsif ( $ypx > 300 ) {
            $Chour = 8;
        }
        else {
            $Chour = 4;
        }
    }
    return $Chour;
}

sub Merge_annotations {
    my @Raw;
    foreach (@_) {
	    unless(defined($_)) { next; }
        if ( $_ =~ /\S/ ) { push @Raw, $_; }
    }
    if ( scalar(@Raw) == 0 ) { return ( "",    "0" ); }
    if ( scalar(@Raw) == 1 ) { return ( $_[0], "1" ); }
    my %Items;
    foreach my $Item (@Raw) {
        my @Matched = amatch( $Item, @Raw );
        foreach my $MItem (@Matched) { $Items{$MItem}++; }
    }
    if ( scalar( keys(%Items) ) == 1 ) { return ( $_[0], "U" ); }
    my @Values = sort { $Items{$b} <=> $Items{$a} } ( keys(%Items) );
    if ( $Items{ $Values[0] } > $Items{ $Values[1] } ) {
        return ( "$Values[0]", "M" );
    }
    if ( $Items{ $Values[0] } >= 2 ) {
        return ( "$Values[0]", "D" );
    }
    return ( "$Values[0]", "X" );
}

# Clean and standardise a latitude
sub CS_latitude {
    my $Latitude  = shift;
    my $Has_north = 0;
    my $Has_south = 0;
    my ( $Degrees, $Minutes );
    my $Result;
    if ( $Latitude =~ /[nN]/ ) { $Has_north = 1; }
    if ( $Latitude =~ /[sS]/ ) { $Has_south = 1; }
    if ( $Latitude =~ /^\D*(\d+)/ ) {
        $Degrees = $1;
        if ( $Latitude =~ /^\D*\d+\D+(\d+)/ ) { $Minutes = $1; }
    }
    if ( defined($Degrees) ) {
        $Result = sprintf "%02d", $Degrees;
        if ( defined($Minutes) ) { $Result .= sprintf " %02d", $Minutes; }
        if ( $Has_north == 1 && $Has_south == 0 ) { $Result .= " N"; }
        if ( $Has_south == 1 && $Has_north == 0 ) { $Result .= " S"; }
        return $Result;
    }
    return $Latitude;
}

# Clean and standardise a longitude
sub CS_longitude {
    my $Longitude = shift;
    my $Has_east  = 0;
    my $Has_west  = 0;
    my ( $Degrees, $Minutes );
    my $Result;
    if ( $Longitude =~ /[eE]/ ) { $Has_east = 1; }
    if ( $Longitude =~ /[wW]/ ) { $Has_west = 1; }
    if ( $Longitude =~ /^\D*(\d+)/ ) {
        $Degrees = $1;
        if ( $Longitude =~ /^\D*\d+\D+(\d+)/ ) { $Minutes = $1; }
    }
    if ( defined($Degrees) ) {
        $Result = sprintf "%02d", $Degrees;
        if ( defined($Minutes) ) { $Result .= sprintf " %02d", $Minutes; }
        if ( $Has_east == 1 && $Has_west == 0 ) { $Result .= " E"; }
        if ( $Has_west == 1 && $Has_east == 0 ) { $Result .= " W"; }
        return $Result;
    }
    return $Longitude;
}

# Clean and standardise a port name
sub CS_port {
    my $Port = shift;
    $Port = lc($Port);
    $Port =~ s/\s+/ /g;
    $Port =~ s/^\s+//;
    $Port =~ s/\s+$//;
    $Port =~ s/[^\w ]//g;
    return ($Port);
}

# Convert to a JSON text string (for passing to R)
sub to_JSON {
    my $Self = shift;
    my $json = JSON->new;

    #$json = $json->utf8;
    $json = $json->allow_blessed(true);
    $json = $json->convert_blessed(true);
    $json = $json->pretty(true);
    my $jTxt = $json->encode($Self);
    return ($jTxt);
}
