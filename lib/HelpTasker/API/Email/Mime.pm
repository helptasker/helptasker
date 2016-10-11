package HelpTasker::API::Email::Mime;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper encode sha1_sum slurp b64_encode);
use MIME::Lite;
use Email::Address;
use Sys::Hostname;
use Data::Random qw(rand_chars);
use File::Type;
use Mojo::Loader qw(data_section);

has 'mime';

sub create {
    my ($self,$body,$args) = @_;
    my $validation = $self->validation->input({
        body=>$body,
        from=>delete $args->{'from'},
        to=>delete $args->{'to'},
        cc=>delete $args->{'cc'},
        subject=>delete $args->{'subject'},
        mime_type=>delete $args->{'mime_type'},
        reply_to=>delete $args->{'reply_to'},
        attachment=>delete $args->{'attachment'},
        auto_template=>delete $args->{'auto_template'},
    });
    $validation->required('body');
    $validation->optional('from');
    $validation->optional('to');
    $validation->optional('cc');
    $validation->optional('reply_to');
    $validation->optional('subject');
    $validation->optional('mime_type')->in(qw/text html/);
    $validation->optional('attachment')->ref('HASH');
    $validation->optional('auto_template');
    $self->api->utils->error_validation($validation);

    my $msg = MIME::Lite->new();

    # Body
    if(defined $validation->param('mime_type') && $validation->param('mime_type') eq 'html'){
        if($validation->param('auto_template')){ 
            my $template = data_section($self->app->config('api_email_mime_template'),$self->app->config('api_email_mime_template_section'));
            my $mt = Mojo::Template->new;
            $body = $mt->vars(1)->render($template, {body => $validation->param('body')});
            $msg->build(Data => encode('UTF-8',$body), Type=>'HTML', Encoding => $self->app->config('api_email_mime_encode'));
        }
        else{
            $msg->build(Data => encode('UTF-8',$validation->param('body')), Type=>'HTML', Encoding => $self->app->config('api_email_mime_encode'));
        }
    }
    else{
        $msg->build(Data => encode('UTF-8',$validation->param('body')), Type=>'TEXT', Encoding => $self->app->config('api_email_mime_encode'));
    }

    # Add charset
    $msg->attr('content-type.charset' => 'utf-8');

    # Header From
    if (ref $validation->param('from') eq 'HASH') {
        my $name    = $self->api->email->utils->mimeword($validation->param('from')->{'name'});
        my $address = $validation->param('from')->{'address'};
        $msg->add(From=>Email::Address->new($name=>$address));
    }
    elsif(defined $validation->param('from')) {
        my $address = $self->api->email->utils->parse_address($validation->param('from'));
        $msg->add(From=>$address->{'mime'});
    }
    else{
        my $address = $self->api->email->utils->parse_address($self->app->config('api_email_mime_default_from'));
        $msg->add(From=>$address->{'mime'});
    }

    # Headers To
    my @data = ();
    for my $item (@{$validation->every_param('to')}){
        if (defined $item && ref $item eq 'HASH') {
            my $name    = $self->api->email->utils->mimeword($item->{'name'});
            my $address = $item->{'address'};
            push(@data, Email::Address->new($name=>$address));
        }
        elsif(defined $item){
            my @result = $self->api->email->utils->parse_address($item);
            push(@data,map { $_->{'mime'} } @result);
        }
    }
    $msg->add(To => join(", ", @data) || $self->api->email->utils->parse_address($self->app->config('api_email_mime_default_to'))->{'mime'} );

    # Headers Сс
    @data = ();
    for my $item (@{$validation->every_param('cc')}){
        if (defined $item && ref $item eq 'HASH') {
            my $name    = $self->api->email->utils->mimeword($item->{'name'});
            my $address = $item->{'address'};
            push(@data, Email::Address->new($name=>$address));
        }
        elsif(defined $item){
            my @result = $self->api->email->utils->parse_address($item);
            push(@data,map { $_->{'mime'} } @result);
        }
    }
    $msg->add(Cc => join(", ", @data)) if(@data);

    # Header Reply-to
    if (ref $validation->param('reply_to') eq 'HASH') {
        my $name    = $self->api->email->utils->mimeword($validation->param('reply_to')->{'name'});
        my $address = $validation->param('reply_to')->{'address'};
        $msg->add('Reply-To'=>Email::Address->new($name=>$address));
    }
    elsif(defined $validation->param('reply_to')) {
        my $address = $self->api->email->utils->parse_address($validation->param('reply_to'));
        $msg->add('Reply-To'=>$address->{'mime'});
    }

    # Attachment
    for my $attachment (@{$validation->every_param('attachment')}){
        if(ref $attachment eq 'HASH'){
            $attachment->{'bytes'} = Mojo::ByteStream->new($attachment->{'bytes'}) if(ref $attachment->{'bytes'} ne 'Mojo::ByteStream');
            my $size = $attachment->{'bytes'}->clone->size;

            if(!defined $attachment->{'type'}){
                my $ft = File::Type->new();
                $attachment->{'type'} = $ft->checktype_contents($attachment->{'bytes'});
            }

            if(!defined $attachment->{'filename'}){
                $attachment->{'filename'} = rand_chars(set => 'alphanumeric', size => 10);
            }

            my %param = (
                Type           => $attachment->{'type'},
                Data           => $attachment->{'bytes'},
                Filename       => $self->api->email->utils->mimeword($attachment->{'filename'}),
                Disposition    =>'attachment',
                Length         => $size,
            );
            $msg->attach(%param);
        }
    }

    # Header Subject
    $msg->add(Subject => $self->api->email->utils->mimeword($validation->param('subject') || $self->app->config('api_email_mime_default_subject') ));

    # Replace header Date
    $msg->replace(Date => Mojo::Date->new());

    # Header Message-ID
    my $message_id = rand_chars(set => 'alphanumeric', size => 50) . '@' . hostname;
    $msg->add('Message-ID' => '<'.$message_id.'>');

    # Header remove X-Mailer
    $msg->delete("X-Mailer");

    $self->mime($msg);
    return $self;
}

sub render {
    my $self = shift;
    return $self->mime->as_string;
}

1;

__DATA__


@@ auto_template

<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type"  content="text/html; charset=UTF-8" />
<title></title>
<style>
    .mail-address a,
    .mail-address a[href] {
        text-decoration: none !important;
        color: #000000 !important;
    }
</style>
</head>
<body>
<table cellpadding="0" cellspacing="0" align="center" width="770px" style="font-family: Arial, sans-serif; color: #000000; background-color: #f8f8f8; background-repeat: repeat; font-size: 14px; background-image: url('https://helptasker.github.io/email/1.png');">
    <tr>
        <td style="padding-top: 60px; padding-right: 70px; padding-bottom: 60px; padding-left: 70px;">
            <img src="" alt="" style="margin-left: 30px; margin-bottom: 15px;">
            <table width="100%" cellpadding="0" cellspacing="0" align="center" style="border-color: #e6e6e6; border-width: 1px; border-style: solid; background-color: #fff; padding-top: 25px; padding-right: 0; padding-bottom: 50px; padding-left: 30px;">
                <tr>
                    <td style="padding: 0 30px 30px;">
                        <p style="font-family: Arial, sans-serif; color: #000000; font-size: 19px; margin-top: 14px; margin-bottom: 0;">
                            Hello! 
                        </p>
                        <p style="font-family: Arial, sans-serif; color: #000000; font-size: 14px; line-height: 17px; margin-top: 30px; margin-bottom: 0;">
                            <%= $body %>
                        </p>
                        <p style="font-family: Arial, sans-serif; color: #000000; font-size: 15px; font-style: italic; margin-top: 30px; margin-bottom: 0;"></p>
                    </td>
                </tr>
            </table>
            <table width="100%" cellpadding="0" cellspacing="0" align="center">
                <tr>
                    <td style="padding-top: 12px; background-image: url('https://helptasker.github.io/email/2.png');"></td>
                </tr>
                <tr>
                    <td style="font-family: Arial, sans-serif; font-size: 12px; color: #888888; padding-right: 30px; padding-left: 30px;"></td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>

=encoding utf8
 
=head1 NAME
 
HelpTasker::API::Email::Mime - The module works with create mime object
 
=head1 SYNOPSIS
 
    my $mime = $t->app->api->email->mime; # Create object HelpTasker::API::Email::Mime

    my $params = {
        from=>'from@email.com',
        to=>'to@email.com',
        subject=>'Subject subject!',
    };

    # Return HelpTasker::API::Email::Mime
    $mime = $mime->create('Body body', $params);

    # Return Mime::Lite
    $mime->mime;

    # Returns message string
    say $mime->mime->as_string;

    # Send HTML
    $mime->create('<h1>Body body</h1>', {
        from=>'from@email.com',
        to=>'to@email.com',
        subject=>'Subject subject!',
        mime_type=>'html',
    });

    # Send HTML auto templating
    $mime->create('<p>Body body</p>', {
        from=>'from@email.com',
        to=>'to@email.com',
        subject=>'Subject subject!',
        mime_type=>'html',
        auto_template=>1,
    });


    # Send Attachments
    use Mojo::Util qw(slurp);
    my $bytes = slurp '/tmp/data.txt';

    $mime->create('Body body', {
        from=>'from@email.com',
        to=>'to@email.com',
        subject=>'Subject subject!',
        attachment=>[{bytes=>$bytes, filename=>'data.txt', type=>'plain/text'}],
    });



=head1 ATTRIBUTES

Available after calling methods create

=head2 mime - Returns MIME::Lite object

    $mime->mime;


=head1 METHODS

=head2 create

    $mime->create('<h1>Body body</h1>', {
        from=>{name=>'Name', address=>'from@example.com'},
        to=>[{name=>'Name1', address=>'to1@example.com'}, {name=>'Name1', address=>'to2@example.com'} ],
        subject=>'Subject subject!',
    });

    # or

    $mime->create('<h1>Body body</h1>', {
        from=>{name=>'Name', address=>'from@example.com'},
        to=>['to1@example.com','to2@example.com'],
        cc=>['cc1@example.com','cc2@example.com'],
        reply_to=>'reply_to@example.com',
        attachment=>"bytes", # or {bytes=>$bytes, filename=>'data.txt', type=>'plain/text'}
    });

=head2 render

    my $params = {
        from=>'from@email.com',
        to=>'to@email.com',
        subject=>'Subject subject!',
    };

    # Return string message
    say $t->app->api->email->mime->create('Body body', $params)->render;


=head1 SEE ALSO

L<MIME::Lite>
 
=cut

