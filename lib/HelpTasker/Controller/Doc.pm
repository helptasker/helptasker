package HelpTasker::Controller::Doc;
use Mojo::Base 'Mojolicious::Controller';
use Pod::Simple::XHTML;
use Pod::Simple::Search;
use Mojo::Util qw(dumper);
use Mojo::Loader qw(data_section);

sub main {
    my $self = shift;
    my $search = Pod::Simple::Search->new;

    my $result = {};
	my ($m) = $search->limit_glob('HelpTasker*')->survey;
    while( my ($item) = each(%{$m})){
        push(@{$result->{'helptasker'}->{'modules'}}, $item);
    }
    
    my @modules = sort {$a cmp $b} @{$result->{'helptasker'}->{'modules'}};
    $result->{'helptasker'}->{'modules'} = \@modules;

    # Search module path
    my $path = $search->find($self->stash('module') || 'HelpTasker');

    if(!defined $path){
        my $url = Mojo::URL->new('https://api.metacpan.org')->path("/v0/pod/".$self->stash('module') || 'HelpTasker');
        my $tx = $self->ua->get($url);
        $result->{'documentation'} = Mojo::DOM->new($tx->res->body);
    }
    else{
        my $parser = Pod::Simple::XHTML->new();
        $parser->output_string(\(my $output));
        $parser->perldoc_url_prefix('/doc/');
        $parser->man_url_prefix('http://manpages.ubuntu.com/manpages/trusty/en/');
	    $parser->html_header(' ');
	    $parser->html_footer(' ');
        $parser->parse_file($path);
        $result->{'documentation'} = Mojo::DOM->new($output);
    }

    my $template = data_section('HelpTasker::Controller::Doc')->{'template'};
    my $mt = Mojo::Template->new;
    for my $e ($result->{'documentation'}->find('pre > code')->each) {
        my $str = $e->content;
        $e->parent->replace("<pre pre class=\"prettyprint lang-perl padding\" style=\"padding:15px;\">$str</pre>");
    }

    $template = $mt->vars(1)->render($template, {result=>$result});
    return $self->render(text => $template, format => 'html');
}

1;

__DATA__

@@ template


<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>HelpTasker documentation</title>
        <script src="/mojo/jquery/jquery.js"></script>
        <script src="/mojo/prettify/run_prettify.js"></script>
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>

        <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://maxcdn.bootstrapcdn.com/bootswatch/3.3.7/flatly/bootstrap.min.css" rel="stylesheet">
        <link href="https://maxcdn.bootstrapcdn.com/font-awesome/4.6.3/css/font-awesome.min.css" rel="stylesheet">

        <!--[if lt IE 9]>
            <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
            <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
        <![endif]-->

        <style type="text/css">
            pre.prettyprint {
                display: block;
                background-color: #333;
            }

            pre .nocode { background-color: none; color: #000 }
            pre .str { color: #ffa0a0 } /* string  - pink */
            pre .kwd { color: #f0e68c; font-weight: bold }
            pre .com { color: #87ceeb } /* comment - skyblue */
            pre .typ { color: #98fb98 } /* type    - lightgreen */
            pre .lit { color: #cd5c5c } /* literal - darkred */
            pre .pun { color: #fff }    /* punctuation */
            pre .pln { color: #fff }    /* plaintext */
            pre .tag { color: #f0e68c; font-weight: bold } /* html/xml tag    - lightyellow */
            pre .atn { color: #bdb76b; font-weight: bold } /* attribute name  - khaki */
            pre .atv { color: #ffa0a0 } /* attribute value - pink */
            pre .dec { color: #98fb98 } /* decimal         - lightgreen */

            ol.linenums { margin-top: 0; margin-bottom: 0; color: #AEAEAE } /* IE indents via margin-left */
            li.L0,li.L1,li.L2,li.L3,li.L5,li.L6,li.L7,li.L8 { list-style-type: none }
            /* Alternate shading for lines */
            li.L1,li.L3,li.L5,li.L7,li.L9 { }

            @media print {
              pre.prettyprint { background-color: none }
              pre .str, code .str { color: #060 }
              pre .kwd, code .kwd { color: #006; font-weight: bold }
              pre .com, code .com { color: #600; font-style: italic }
              pre .typ, code .typ { color: #404; font-weight: bold }
              pre .lit, code .lit { color: #044 }
              pre .pun, code .pun { color: #440 }
              pre .pln, code .pln { color: #000 }
              pre .tag, code .tag { color: #006; font-weight: bold }
              pre .atn, code .atn { color: #404 }
              pre .atv, code .atv { color: #060 }
            }

            body {
                padding-top: 80px
            }

            @media (min-width: 1200px){
                .container {
                    width: 1366px;
                }
            }

            h1 {
                font-size: 22px;
            }

            h2 {
                font-size: 20px;
            }
        </style>

    </head>
    <body>

        <nav class="navbar navbar-default navbar-fixed-top">
            <div class="container">
                <div class="navbar-header">
                    <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
                        <span class="sr-only">Toggle navigation</span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </button>
                    <a class="navbar-brand" href="/doc/">HelpTasker documentation</a>
                </div>
                <!--
                <div id="navbar" class="collapse navbar-collapse">
                    <ul class="nav navbar-nav">
                        <li><a href="#">Modules</a></li>
                    </ul>
                </div>
                -->
            </div>
        </nav>

        <div class="container">
            <div class="row">
                <div class="col-md-3">
                    <div class="list-group table-of-contents">
                        % for my $item (@{$result->{'helptasker'}->{'modules'}}) {
                            <a class="list-group-item" href="/doc/<%= $item %>"><%= $item %></a>
                        % }
                    </div>
                </div>
                <div class="col-md-9">
                    <%= $result->{'documentation'} %>
                </div>
            </div>


        </div>
    </body>
</html>





