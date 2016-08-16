package HelpTasker::Email::Message;
use Mojo::Base -base;
use Mojo::Util qw(dumper encode sha1_sum trim punycode_encode);
use MIME::Lite;
use Email::Address;
use MIME::Words qw(encode_mimeword);
use Sys::Hostname;
use Data::Random qw(:all);

has 'from';
has 'to' => sub { [] };
has 'cc' => sub { [] };
has 'subject';
has 'reply_to';
has 'date' => sub { Mojo::Date->new(time + 60) };
has 'x_mailer';
has 'message_id';
has 'content_type';

sub to_datetime {
    my $self = shift;
    my $date = Mojo::Date->new($self->date)->to_datetime;
    return $date;
}

sub mime {
    my $self = shift;

    my $msg = MIME::Lite->new();

    # Body
    $msg->build(Data => 'test', Encoding => 'base64');

    # From
    if (ref $self->from eq 'HASH') {
        $msg->add(From => Email::Address->new($self->mimeword($self->from->{'name'}) => $self->from->{'address'}));
    }
    else {
        my $result = $self->parse_address($self->from);
        $self->from({name=>$result->{'name'}, address=>$result->{'address'}});
        $msg->add(From=>$result->{'mime'});
    }

    # To
    my @data = ();
    for (@{$self->to}){
        if (defined $_ && ref $_ eq 'HASH') {
            push(@data, Email::Address->new($self->mimeword($_->{'name'}) => $_->{'address'}));
        }
        elsif(defined $_){
            my @result = $self->parse_address($_);
            push(@data,map { $_->{'mime'} } @result);
        }
    }
    $msg->add(To => join(", ", @data));

    # Сс
    @data = ();
    for (@{$self->cc}){
        if (defined $_ && ref $_ eq 'HASH') {
            push(@data, Email::Address->new($self->mimeword($_->{'name'}) => $_->{'address'}));
        }
        elsif(defined $_){
            my @result = $self->parse_address($_);
            push(@data,map { $_->{'mime'} } @result);
        }
    }
    $msg->add(Cc => join(", ", @data));

    # Reply-to
    if(my $reply_to = $self->reply_to){
        if (ref $reply_to eq 'HASH') {
            $msg->add('Reply-To' => Email::Address->new($self->mimeword($self->reply_to->{'name'}) => $self->reply_to->{'address'}));
        }
        else{
            $reply_to = $self->parse_address($reply_to);
            $msg->add('Reply-To' => $reply_to->{'mime'});
        }
    }

    # Subject
    $msg->add(Subject => $self->mimeword($self->subject)) if(defined $self->subject);

    # Replace Date
    $msg->replace("Date" => Mojo::Date->new($self->date));

    my $message_id = rand_chars(set => 'alphanumeric', size => 40) . '@' . hostname;
    $msg->add('Message-ID' => $message_id);

    $msg->delete("X-Mailer");
    return $msg;
}

sub render {
    my $self = shift;
    return $self->mime->as_string;
}

sub mimeword {
    my ($self,$string,$type) = @_;
    return encode_mimeword(encode('UTF-8', $string), $type // 'b', 'UTF-8');
}

sub parse_address {
    my ($self,$string) = @_;

    my @result = ();
    for my $data (Email::Address->parse($string)) {
        my $address  = $data->address;
        my $name     = $data->name;
        my $user     = $data->user;
        my $host     = $data->host;
        my $original = $data->original;

        $address = trim(lc($address));
        $host    = trim(lc($host));
        my $mime = Email::Address->new($self->mimeword($name) => $address);
        push(@result, {name => $name, address => $address, user => $user, host => $host, original => $original, mime=>$mime});
    }
    return wantarray ? @result : shift @result;
}

#su b

1;

