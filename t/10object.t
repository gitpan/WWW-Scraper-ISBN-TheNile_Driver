#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 65;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'TheNile';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '0099547937' => [
        [ 'is',     'isbn',         '9780099547938' ],
        [ 'is',     'isbn10',       '0099547937'    ],
        [ 'is',     'isbn13',       '9780099547938' ],
        [ 'is',     'ean13',        '9780099547938' ],
        [ 'is',     'title',        'Ford County'   ],
        [ 'is',     'author',       'John Grisham'  ],
        [ 'is',     'publisher',    'Cornerstone'   ],
        [ 'is',     'pubdate',      '2010'          ],
        [ 'is',     'binding',      'Paperback'     ],
        [ 'is',     'pages',        '352'           ],
        [ 'is',     'width',        '111'           ],
        [ 'is',     'height',       '178'           ],
        [ 'is',     'weight',       undef           ],
        [ 'is',     'image_link',   'http://tncdn.net/1/978/009/9547938.jpg' ],
        [ 'is',     'thumb_link',   'http://tncdn.net/1/978/009/9547938.jpg' ],
        [ 'like',   'description',  qr|John Grisham takes you into the heart of America's Deep South| ],
        [ 'like',   'book_link',    qr|http://www.thenile.com.au/books/John-Grisham/Ford-County/9780099547938/| ]
    ],
    '9780007203055' => [
        [ 'is',     'isbn',         '9780007203055'             ],
        [ 'is',     'isbn10',       '0007203055'                ],
        [ 'is',     'isbn13',       '9780007203055'             ],
        [ 'is',     'ean13',        '9780007203055'             ],
        [ 'like',   'author',       qr/Simon Ball/              ],
        [ 'is',     'title',        q|Bitter Sea|               ],
        [ 'is',     'publisher',    'Harpercollins Publishers'  ],
        [ 'is',     'pubdate',      '2010'                      ],
        [ 'is',     'binding',      'Paperback'                 ],
        [ 'is',     'pages',        416                         ],
        [ 'is',     'width',        undef                       ],
        [ 'is',     'height',       undef                       ],
        [ 'is',     'weight',       321                         ],
        [ 'is',     'image_link',   'http://tncdn.net/1/978/000/7203055.jpg'    ],
        [ 'is',     'thumb_link',   'http://tncdn.net/1/978/000/7203055.jpg'    ],
        [ 'like',   'description',  qr|The Mediterranean was indeed|            ],
        [ 'like',   'book_link',    qr|http://www.thenile.com.au/books/Simon-Ball/Bitter-Sea/9780007203055/| ]
    ],
    '9780718155896' => [
        [ 'is',     'isbn',         '9780718155896'             ],
        [ 'is',     'isbn10',       '0718155890'                ],
        [ 'is',     'isbn13',       '9780718155896'             ],
        [ 'is',     'ean13',        '9780718155896'             ],
        [ 'is',     'author',       q|Clive Cussler, Justin Scott|  ],
        [ 'is',     'title',        q|The Spy|                  ],
        [ 'is',     'publisher',    'Penguin Books Ltd'         ],
        [ 'is',     'pubdate',      '2010'                      ],
        [ 'is',     'binding',      'Paperback'                 ],
        [ 'is',     'pages',        436                         ],
        [ 'is',     'width',        152                         ],
        [ 'is',     'height',       230                         ],
        [ 'is',     'weight',       undef                       ],
        [ 'is',     'image_link',   'http://tncdn.net/1/978/071/8155896.jpg'    ],
        [ 'is',     'thumb_link',   'http://tncdn.net/1/978/071/8155896.jpg'    ],
        [ 'like',   'description',  qr|international tensions are mounting as the world plunges towards war| ],
        [ 'like',   'book_link',    qr|http://www.thenile.com.au/books/Clive-Cussler-Justin-Scot/The-Spy/9780718155896/| ],
    ],
    
    '9781408307557' => [
        [ 'is',     'pages',        48                          ],
        [ 'is',     'width',        198                         ],
        [ 'is',     'height',       129                         ],
        [ 'is',     'weight',       150                         ],
    ],
);

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2 }


###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", $tests+1   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers($DRIVER);

    # this ISBN doesn't exist
	my $isbn = "1234567890";
    my $record;

    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    }
    elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } else {
		like($record->error,qr/Failed to find that book|website appears to be unavailable/);
    }

    for my $isbn (keys %tests) {
        $record = $scraper->search($isbn);
        my $error  = $record->error || '';

        SKIP: {
            skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable/);

            unless($record->found) {
                diag($record->error);
            }

            is($record->found,1);
            is($record->found_in,$DRIVER);

            my $book = $record->book;
            for my $test (@{ $tests{$isbn} }) {
                if($test->[0] eq 'ok')          { ok(       $book->{$test->[1]},             ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'is')       { is(       $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'isnt')     { isnt(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'like')     { like(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'unlike')   { unlike(   $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); }

            }

            #use Data::Dumper;
            #diag("book=[".Dumper($book)."]");
        }
    }
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    system("ping -q -c 1 $domain >/dev/null 2>&1");
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}
