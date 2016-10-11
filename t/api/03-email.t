use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper b64_decode);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

ok(ref $t->app->api->email eq 'HelpTasker::API::Email', 'ok object');

subtest 'utils' => sub {
    ok(ref $t->app->api->email->utils eq 'HelpTasker::API::Email::Utils', 'ok object message');

    ok($t->app->api->email->utils->validator('devnull@example.com') == 1, 'email valid');
    ok($t->app->api->email->utils->validator('devnull@@examplessssssss.com') != 1, 'email invalid');
    ok($t->app->api->email->utils->validator('devnull@example.com', {mxcheck=>1}) != 1, 'email invalid (mx check)');
    ok($t->app->api->email->utils->validator('devnull@example.def', {tldcheck=>1}) != 1, 'email invalid (tld check)');

    my $result = $t->app->api->email->utils->parse_address('devnull@example.com');
    ok($result->{'address'} eq 'devnull@example.com', 'parse_address address');
    ok($result->{'host'} eq 'example.com', 'parse_address host');
    ok($result->{'name'} eq 'devnull', 'parse_address name');
    ok($result->{'original'} eq 'devnull@example.com', 'parse_address name');
    ok($result->{'user'} eq 'devnull', 'parse_address user');
    ok(ref $result->{'mime'} eq 'Email::Address', 'parse_address mime');

    $result = $t->app->api->email->utils->parse_address('"Test User" <devnull@example.com>');
    ok($result->{'name'} eq 'Test User', 'parse_address name');

    ok($t->app->api->email->utils->mimeword("Казерогова Лилу") eq '=?UTF-8?B?0JrQsNC30LXRgNC+0LPQvtCy0LAg0JvQuNC70YM=?=', 'ok mimeword');
};

subtest 'mime' => sub {
    $t->app->api->migration->clear; # reset db
    ok(ref $t->app->api->email->mime eq 'HelpTasker::API::Email::Mime', 'ok object message');

    my $render = $t->app->api->email->mime->create('Привет')->render;
    like($render, qr{0J/RgNC40LLQtdGC}, 'check body');
    like($render, qr{From\:\s=\?UTF\-8\?B\?ZGV2bnVsbA==\?=\s\<devnull\@helptasker\.org\>}, 'check default from');
    like($render, qr{To\:\s=\?UTF\-8\?B\?ZGV2bnVsbA==\?=\s\<devnull\@helptasker\.org\>}, 'check default to');
    like($render, qr{Subject:\s=\?UTF-8\?B\?Tm8gU3ViamVjdA==\?=}, 'check default subject');
    like($render, qr{Message\-Id\:\s\<[a-z0-9]+\@[a-z0-9]+\.[a-z0-9]+\>}i, 'check default message-id');

    $render = $t->app->api->email->mime->create('Привет', {from=>'devnull@example.com', to=>'devnull@example.com', subject=>'test'})->render;
    like($render, qr{From:\s=\?UTF-8\?B\?ZGV2bnVsbA==\?=\s<devnull\@example.com>}, 'check From');
    like($render, qr{To:\s=\?UTF-8\?B\?ZGV2bnVsbA==\?=\s<devnull\@example.com>}, 'check To');
    like($render, qr{Subject:\s=\?UTF-8\?B\?dGVzdA==\?=}, 'check Subject');

    $render = $t->app->api->email->mime->create('Привет', {to=>'devnull1@example.com,devnull1@example.com'})->render;
    like($render, qr{To:\s=\?UTF-8\?B\?ZGV2bnVsbDE=\?=\s<devnull1\@example.com>\,\s=\?UTF-8\?B\?ZGV2bnVsbDE=\?=\s<devnull1\@example\.com>}, 'check To multi (1)');

    $render = $t->app->api->email->mime->create('Привет', {to=>['devnull1@example.com','devnull1@example.com']})->render;
    like($render, qr{To:\s=\?UTF-8\?B\?ZGV2bnVsbDE=\?=\s<devnull1\@example.com>\,\s=\?UTF-8\?B\?ZGV2bnVsbDE=\?=\s<devnull1\@example\.com>}, 'check To multi (2)');

    $render = $t->app->api->email->mime->create('Привет', {cc=>'devnull1@example.com,devnull1@example.com'})->render;
    like($render, qr{Cc:\s=\?UTF-8\?B\?ZGV2bnVsbDE=\?=\s<devnull1\@example.com>\,\s=\?UTF-8\?B\?ZGV2bnVsbDE=\?=\s<devnull1\@example\.com>}, 'check Cc multi (1)');

    $render = $t->app->api->email->mime->create('Привет', {cc=>['devnull1@example.com','devnull1@example.com']})->render;
    like($render, qr{Cc:\s=\?UTF-8\?B\?ZGV2bnVsbDE=\?=\s<devnull1\@example.com>\,\s=\?UTF-8\?B\?ZGV2bnVsbDE=\?=\s<devnull1\@example\.com>}, 'check Cc multi (2)');

    $render = $t->app->api->email->mime->create('Привет', {reply_to=>'reply_to@example.com'})->render;
    like($render, qr{Reply-To:\s=\?UTF-8\?B\?cmVwbHlfdG8=\?=\s<reply_to\@example.com>}, 'check Reply-To');

    my $gif = 'R0lGODlhyADIAMIAAP/yAAoKCgAAAcRiAO0cJAAAAAAAAAAAACH5BAEAAAUALAAAAADIAMgAAAP+WLrc/jDKSau9OOvNu/9gKI5kaZ5oqq5s675wLM90bd94ru987//AoHBILBqPyKRyyWw6n9CodEqtWq/YrHbL7Xq/4LB4TC6bz+i0es1uu9/wuHxOr9vv+Lx+z+/7/4CBgoOEhYaHiImKi4yNjo+QkZKTlJWWl5iZmpucnZ6foKGio6SlpqeoqaqrrK2ur7CxsrO0tba3uLm6u7y9vr/AwcLDxMXGx8jJysvMzc7P0NHS09TV1tfY2drb3N3e3+Dh4uPk5eaTAukCzOrry+3s6sjtAfUB8MP09vjC+vX8wfzdk/dLoL2B6YAZ3EfQ18J/DXs9ROjOobqDBwGSmHj+ENJEjSM42vN4ESPEhCdE1iOZzuTJiiVUBmApwCVFEO3aAdjJs+fOjo8+RuSQU53PowCAOhKK0kPRdEh9Km3EFCbRp1F7TmWkEylIC12zZt26KKzPrxXMij1KVpFanmgpvF3Ls22iuQDiTsBL1y6Yp4AD28yI1evQvUbprvX7JbDjnIMZFo2q1wFfxT9HnnnMuWZkingrN7iMmbGXzo8/g058VDQD0opNZ5F5ELNtw00jwL4tGwtte7eDwz1smbVwpL2v/K53PLjo3baTW1keoPnt58at19VsRqZW4NrPEi8AXbj02SUjf2cevifa8sHP+04/eH319sNzv86OP/P+ys302WRffzu9x19/8m2BWkvg9WcgVMepBseCnrHn4Hjw2WfThAvWRuCDAjQn4RsUenihfgtkuF1kgJiIn2xmDSDjAPYx4mJ7MBo3I40rzrTIjeHlCOFOO9b4Y4MvcqebjjMaqYiLoR2YlJIQtLPjlTMmqAeUUuIlpABYYqllHlwOKZ6ZTi6ZTphXjolHmSHiFidbVD5gJZtZ1mnIQQT0ScBtfv7ZI4V3iqlnIXz6CaiigxK6Zphu3pFon4tS2qijbEZqx6SCYhaofY4+auh/jgCpXZE8oSqWpn2Yap2qAMAaFat8uNocrLIid6iNSLaHa5OL7fqIarf9KmNfwpaK+lmxwBLZ7FjJNkKsbcbyuGq0vKpH7bO50klqJ7YSmCYn4Yrrn4+elGsurYeoKy67e/ZqrrfogivvvONu4i6B8CJ6L77nguKigD0O7FK+mhhskoZIEhzwJwpjxLCFUy7co8ANH1xwxhY/LIpdIB/qmr6Hhvztfih+XPLKJ6c4HsYtK2ByvShb9UQCADs=';
    $render = $t->app->api->email->mime->create('Привет', {attachment=>{bytes=>b64_decode($gif), filename=>'картинка.gif', type=>'image/gif'} })->render;
    like($render, qr{Content-Type: image/gif; name=\"=\?UTF-8\?B\?0LrQsNGA0YLQuNC90LrQsC5naWY=\?="}, 'Attachment Ok');

    $gif = b64_decode('R0lGODlhyADIAMIAAP/yAAoKCgAAAcRiAO0cJAAAAAAAAAAAACH5BAEAAAUALAAAAADIAMgAAAP+WLrc/jDKSau9OOvNu/9gKI5kaZ5oqq5s675wLM90bd94ru987//AoHBILBqPyKRyyWw6n9CodEqtWq/YrHbL7Xq/4LB4TC6bz+i0es1uu9/wuHxOr9vv+Lx+z+/7/4CBgoOEhYaHiImKi4yNjo+QkZKTlJWWl5iZmpucnZ6foKGio6SlpqeoqaqrrK2ur7CxsrO0tba3uLm6u7y9vr/AwcLDxMXGx8jJysvMzc7P0NHS09TV1tfY2drb3N3e3+Dh4uPk5eaTAukCzOrry+3s6sjtAfUB8MP09vjC+vX8wfzdk/dLoL2B6YAZ3EfQ18J/DXs9ROjOobqDBwGSmHj+ENJEjSM42vN4ESPEhCdE1iOZzuTJiiVUBmApwCVFEO3aAdjJs+fOjo8+RuSQU53PowCAOhKK0kPRdEh9Km3EFCbRp1F7TmWkEylIC12zZt26KKzPrxXMij1KVpFanmgpvF3Ls22iuQDiTsBL1y6Yp4AD28yI1evQvUbprvX7JbDjnIMZFo2q1wFfxT9HnnnMuWZkingrN7iMmbGXzo8/g058VDQD0opNZ5F5ELNtw00jwL4tGwtte7eDwz1smbVwpL2v/K53PLjo3baTW1keoPnt58at19VsRqZW4NrPEi8AXbj02SUjf2cevifa8sHP+04/eH319sNzv86OP/P+ys302WRffzu9x19/8m2BWkvg9WcgVMepBseCnrHn4Hjw2WfThAvWRuCDAjQn4RsUenihfgtkuF1kgJiIn2xmDSDjAPYx4mJ7MBo3I40rzrTIjeHlCOFOO9b4Y4MvcqebjjMaqYiLoR2YlJIQtLPjlTMmqAeUUuIlpABYYqllHlwOKZ6ZTi6ZTphXjolHmSHiFidbVD5gJZtZ1mnIQQT0ScBtfv7ZI4V3iqlnIXz6CaiigxK6Zphu3pFon4tS2qijbEZqx6SCYhaofY4+auh/jgCpXZE8oSqWpn2Yap2qAMAaFat8uNocrLIid6iNSLaHa5OL7fqIarf9KmNfwpaK+lmxwBLZ7FjJNkKsbcbyuGq0vKpH7bO50klqJ7YSmCYn4Yrrn4+elGsurYeoKy67e/ZqrrfogivvvONu4i6B8CJ6L77nguKigD0O7FK+mhhskoZIEhzwJwpjxLCFUy7co8ANH1xwxhY/LIpdIB/qmr6Hhvztfih+XPLKJ6c4HsYtK2ByvShb9UQCADs=');
    $render = $t->app->api->email->mime->create('Привет', {attachment=>[{bytes=>$gif, filename=>'картинка1.gif', type=>'image/gif'}, {bytes=>$gif, filename=>'картинка2.gif', type=>'image/gif'}] })->render;
    like($render, qr{Content-Type: image/gif; name=\"=\?UTF-8\?B\?0LrQsNGA0YLQuNC90LrQsDEuZ2lm\?="}, 'Attachment Ok');
};

done_testing();

