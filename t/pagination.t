use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'BootstrapHelpers';

my $m = \&Mojolicious::Plugin::BootstrapHelpers::_pagination;

is_deeply( [$m->(1,1,1,11)], [1], 'Single page' );
is_deeply( [$m->(1,1,2,11)], [1,2], 'Two pages' );
is_deeply( [$m->(1,1,3,11)], [1,2,3], 'Two pages' );

is_deeply( [$m->(1,$_,7,5)], [1,2,3,7], "Short pagination (pos $_)" ) foreach( 1..3 );
is_deeply( [$m->(1,4,7,5)], [1,4,7], "Short pagination (pos 4)" );
is_deeply( [$m->(1,$_,7,5)], [1,5,6,7], "Short pagination (pos $_)" ) foreach( 5..7 );

is_deeply( [$m->(1,$_,10,11)], [1..10], 'Pagination with few pages' ) foreach( 1..10 );

is_deeply( [$m->(1,$_,100,11)], [1..7,98..100], "Long pagination, 11 items (pos $_)" ) foreach( 1..6 );
is_deeply( [$m->(1,$_,100,11)], [1..3,($_-1)..($_+1),98..100], "Long pagination, 11 items (pos $_)" ) foreach( 7..94 );
is_deeply( [$m->(1,$_,100,11)], [1..3,94..100], "Long pagination, 11 items (pos $_)" ) foreach( 95..100 );

is_deeply( [$m->(1,$_,100,12)], [1..8,98..100], "Long pagination, 12 items (pos $_)" ) foreach( 1..7 );
is_deeply( [$m->(1,$_,100,12)], [1..3,($_-2)..($_+1),98..100], "Long pagination, 12 items (pos $_)" ) foreach( 8..93 );
is_deeply( [$m->(1,$_,100,12)], [1..3,93..100], "Long pagination, 12 items (pos $_)" ) foreach( 94..100 );

is_deeply( [$m->(1,$_,100,21)], [1..14,95..100], "Long pagination, 21 items (pos $_)" ) foreach( 1..13 );
is_deeply( [$m->(1,$_,100,21)], [1..6,($_-3)..($_+3),95..100], "Long pagination, 21 items (pos $_)" ) foreach( 14..87 );
is_deeply( [$m->(1,$_,100,21)], [1..6,87..100], "Long pagination, 21 items (pos $_)" ) foreach( 88..100 );

is_deeply( [$m->(1,$_,100,22)], [1..15,95..100], "Long pagination, 22 items (pos $_)" ) foreach( 1..14 );
is_deeply( [$m->(1,$_,100,22)], [1..6,($_-4)..($_+3),95..100], "Long pagination, 22 items (pos $_)" ) foreach( 15..86 );
is_deeply( [$m->(1,$_,100,22)], [1..6,86..100], "Long pagination, 22 items (pos $_)" ) foreach( 87..100 );


done_testing();
