package HelpTasker::Email::Message;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper encode sha1_sum slurp);
use MIME::Lite;
use Email::Address;
use Sys::Hostname;
use Data::Random qw(:all);
use File::Type;

has 'from';
has 'to' => sub { [] };
has 'cc' => sub { [] };
has 'subject';
has 'reply_to';
has 'date' => sub { Mojo::Date->new(time + 60) };
has 'x_mailer';
has 'message_id';
has 'content_type';
has 'body';
has 'attachment' => sub { [] };

sub mime {
    my $self = shift;

    my $msg = MIME::Lite->new();

    my $head = MIME::Head->new;
    $head->replace('content-type', $self->content_type);

    # Body
    if($head->mime_type eq 'plain/text'){
        $msg->build(Data => encode('UTF-8',$self->body), Type=>'TEXT', Encoding => 'base64');
    }
    elsif($head->mime_type eq 'text/html'){
        $msg->build(Data => encode('UTF-8',$self->body), Type=>'HTML', Encoding => 'base64');
    }

    # Add charset
    $msg->attr('content-type.charset' => 'utf-8');

    # From
    if (ref $self->from eq 'HASH') {
        $msg->add(From => Email::Address->new($self->api->email->utils->mimeword($self->from->{'name'}) => $self->from->{'address'}));
    }
    else {
        my $result = $self->api->email->utils->parse_address($self->from);
        $self->from({name=>$result->{'name'}, address=>$result->{'address'}});
        $msg->add(From=>$result->{'mime'});
    }

    # To
    my @data = ();
    for (@{$self->to}){
        if (defined $_ && ref $_ eq 'HASH') {
            push(@data, Email::Address->new($self->api->email->utils->mimeword($_->{'name'}) => $_->{'address'}));
        }
        elsif(defined $_){
            my @result = $self->api->email->utils->parse_address($_);
            push(@data,map { $_->{'mime'} } @result);
        }
    }
    $msg->add(To => join(", ", @data));

    # Сс
    @data = ();
    for (@{$self->cc}){
        if (defined $_ && ref $_ eq 'HASH') {
            push(@data, Email::Address->new($self->api->email->utils->mimeword($_->{'name'}) => $_->{'address'}));
        }
        elsif(defined $_){
            my @result = $self->api->email->utils->parse_address($_);
            push(@data,map { $_->{'mime'} } @result);
        }
    }
    $msg->add(Cc => join(", ", @data));

    # Reply-to
    if(my $reply_to = $self->reply_to){
        if (ref $reply_to eq 'HASH') {
            $msg->add('Reply-To' => Email::Address->new($self->api->email->utils->mimeword($self->reply_to->{'name'}) => $self->reply_to->{'address'}));
        }
        else{
            $reply_to = $self->api->email->utils->parse_address($reply_to);
            $msg->add('Reply-To' => $reply_to->{'mime'});
        }
    }

    # Attachment
    for my $attach (@{$self->attachment}){
        if(ref $attach eq 'HASH'){
            $attach->{'bytes'} = Mojo::ByteStream->new($attach->{'bytes'}) if(ref $attach->{'bytes'} ne 'Mojo::ByteStream');

            if(!defined $attach->{'type'}){
                my $ft = File::Type->new();
                $attach->{'type'} = $ft->checktype_contents($attach->{'bytes'});
            }

            $msg->attach(
                Type        => $attach->{'type'},
                Data        => $attach->{'bytes'},
                Filename    => $self->api->email->utils->mimeword($attach->{'filename'}),
                Disposition =>'attachment',
            );
        }
    }

    # Subject
    $msg->add(Subject => $self->api->email->utils->mimeword($self->subject)) if(defined $self->subject);

    # Replace Date
    $msg->replace("Date" => Mojo::Date->new($self->date));

    # Message-ID
    my $message_id = rand_chars(set => 'alphanumeric', size => 40) . '@' . hostname;
    $msg->add('Message-ID' => '<'.$message_id.'>');

    $msg->delete("X-Mailer");
    return $msg;
}

sub render {
    my $self = shift;
    return $self->mime->as_string;
}

sub to_datetime {
    my $self = shift;
    my $date = Mojo::Date->new($self->date)->to_datetime;
    return $date;
}

1;
