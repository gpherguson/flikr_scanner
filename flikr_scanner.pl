#!/usr/bin/perl

use strict;
use warnings;

use HTML::TreeBuilder;
use LWP::Simple;
use CGI;

my $FLICKR_URL         = 'http://www.flickr.com';
my $QUERY_TEMPLATE     = "$FLICKR_URL/search/?q=%s+rodeo++&m=tags";
my $USER_PAGE_TEMPLATE = "$FLICKR_URL%s";
my @RODEOS             = (

    # simple city names
    qw(
      albuquerque
      flagstaff
      kingman
      mescalero
      page
      payson
      prescott
      scottsdale
      tucson
      williams
      yuma
      ),

    # compound city names
    'sante fe',
    'silver city',

    # long names
    'desert thunder',
    'fiesta de los vaqueros',
    'new mexico state fair',
    'parada del sol',
    'pine country',
    'worlds oldest'
);

my $TITLE = 'Images found on Flickr';
my $CSS   =<<END_CSS;
span.found_thumbnail { border: 1px solid gray;   } 
img.found_img        { border: 1px solid silver; } 
a.found_a            {                           } 
span.found_img_text  {                           } 
END_CSS

my %images = ();

foreach my $rodeo (@RODEOS)
{
    my $url = sprintf( $QUERY_TEMPLATE, $rodeo );
    if ( my $html = get($url) )
    {

        if ( $html =~ m/find any photos/i )
        {
            print "Nothing found for $rodeo.\n";
            next;
        }

        $images{$rodeo} = [];

        # my ($num_images_found) = ( $html =~ m/found (\d+) photos?/i );
        # print $num_images_found, " images found for $rodeo\n";

        my $more_pages = 1;
        while ($more_pages)
        {
            my $tree = HTML::TreeBuilder->new_from_content($html);

            foreach my $_td ( $tree->look_down( '_tag' => 'td', 'class' => 'DetailPic' ) )
            {
                my $_a_href = sprintf( $USER_PAGE_TEMPLATE, $_td->look_down( '_tag' => 'a' )->attr('href') );

                my $_img = $_td->look_down( '_tag' => 'img' );
                my $_src = $_img->attr('src');
                push @{ $images{$rodeo} },
                  {
                    'src'       => $_src,
                    'width'     => $_img->attr('width'),
                    'height'    => $_img->attr('height'),
                    'user_page' => $_a_href,
                  };
            }
            $more_pages = $tree->look_down( '_tag' => 'a', 'class' => 'Next' );
            if ($more_pages)
            {
                $url = $more_pages->attr('href');
                $html = get($url) if ($url);
                redo if ($html);
            }
        }
    }
}

my $q = new CGI;
print $q->header, $q->start_html( '-style' => { '-code' => $CSS }, '-title' => $TITLE ), $q->start_table(), "\n";
foreach my $rodeo (@RODEOS)
{
    next if ( !exists( $images{$rodeo} ) );

    my @images_from_rodeo = @{ $images{$rodeo} };

    print $q->Tr(
        $q->td(
            $q->span( { '-class' => 'found_rodeo_name' }, $rodeo ),
            $q->span(
                { '-class' => 'found_thumbnail', },
                [
                    map {
                        $q->a(
                            {
                                '-class' => 'found_a',
                                '-href'  => $_->{'user_page'},
                            },
                            $q->img(
                                {
                                    '-class'  => 'found_img',
                                    '-height' => $_->{'height'},
                                    '-src'    => $_->{'src'},
                                    '-width'  => $_->{'width'},
                                }
                            )
                          )
                      } @images_from_rodeo
                ]
            )
        )
      ),
      "\n";
}
print $q->end_table, $q->end_html, "\n";
