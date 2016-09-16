package HelpTasker::Email::Parse;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper sha1_sum trim);
use MIME::Parser;
use MIME::WordDecoder;
use HTTP::Date qw/str2time time2isoz/;
use List::MoreUtils qw(uniq);
use Text::Iconv;
use Carp qw(croak);
use Net::IP;
use HTML::Strip;
use Try::Tiny;

sub parse {
    my ($self, $message) = @_;

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);

    #$parser->decode_headers(1);

    my $entity = $parser->parse_data($message);

    my $mime = $self->headers($entity);
    my $body = $self->mime_body($entity);

    #say mime_to_perl_string($head->get('Subject'));
    #say dumper $mime;
    return $mime;
}

sub mime_body {
    my ($self, $entity) = @_;
    #say $entity->effective_type;

    #if($entity->effective_type eq 'multipart/alternative');

    if ($entity->is_multipart()) {
        for my $part ($entity->parts) {
            my ($body, $attachment) = $self->mime_body_part($part);
        }
    }
    else {
        my ($body, $attachment) = $self->mime_body_part($entity);
    }
    return;
}


sub mime_body_part {
    my ($self, $entity) = @_;

    for my $part ($entity->parts_DFS) {
        my $content_type = $part->effective_type;
        $content_type = lc($content_type) if ($content_type);
        next if (defined $content_type && $content_type eq 'application/pkcs7-signature');
        #say '---------------- ' . $content_type . '------------------';

        if ($part->bodyhandle) {
            my $body   = $part->bodyhandle;
            my $string = $body->as_string;

            if ($content_type eq 'text/plain' || $content_type eq 'text/html') {
                $body->binmode(0);
                my $charset = $part->head->mime_attr("content-type.charset");
                $charset = lc($charset) if (defined $charset && $charset);
                if (defined $charset && $charset ne 'utf-8') {
                    my $iconv;
                    try {
                        $iconv = Text::Iconv->new($charset, 'utf-8');
                    }
                    catch {
                        croak $_;
                    };
                    $string = $iconv->convert($string) if (ref $iconv eq 'Text::IconvPtr');
                }
                #say $string;
            }
            else {
                my $filename = $part->head->recommended_filename;
                chomp($filename);

                #say dumper $part->head;
            }
        }
    }
    return;
}

sub headers {
    my ($self, $entity) = @_;

    my $header = {};

    my $head = $entity->head;
    if(my $subject = $head->get('Subject')){
        $header->{'subject'} = mime_to_perl_string($subject);
        $header->{'subject'} =~ s/\n//gx;
        $header->{'subject'} =~ s/^\s+|\s+$//gx;
        chomp $header->{'subject'};
    }
    else{
        $header->{'subject'} = undef;
    }

    # Header parse message-id
    if ($head->count('message-id') >= 1) {
        $header->{'message_id'}->{'value'} = $head->get('message-id');
        $header->{'message_id'}->{'value'} =~ s/[\<\>]{1}//gx;
        chomp($header->{'message_id'}->{'value'});
        $header->{'message_id'}->{'hash'} = sha1_sum($header->{'message_id'}->{'value'});
    }

    # Header parse From, Reply-To
    for my $fields (qw/from reply-to return-path/) {
        if ($head->count($fields) >= 1) {
            $header->{$fields} = $self->api->email->utils->parse_address(mime_to_perl_string($head->get($fields)));
            delete $header->{$fields}->{'mime'};
        }
    }

    $header->{'reply_to'}    = delete $header->{'reply-to'}    if (defined $header->{'reply-to'});
    $header->{'return_path'} = delete $header->{'return-path'} if (defined $header->{'return-path'});

    # Header parse To, Cc
    for my $fields (qw/to cc/) {
        if ($head->count($fields) >= 1) {
            my @fields = ();
            for my $address ($head->get_all($fields)) {
                my @val = $self->api->email->utils->parse_address(mime_to_perl_string($address));
                delete $_->{'mime'} for (@val);
                push(@fields, @val);
            }
            my %tmp = ();
            @fields = grep { !$tmp{$_->{'address'}}++; } @fields;
            push(@{$header->{$fields}}, @fields);
        }
    }

    # Header Date
    if ($head->count('date') == 1) {
        my $date = $head->get('date');
        chomp($date);
        my $time = str2time($date);
        $time             = time() if (time() < $time);
        $time             = time2isoz($time);
        $header->{'date'} = $time;
        $header->{'date'} = Mojo::Date->new($header->{'date'});
    }

    # Header Feedback-ID
    if ($head->count('feedback-id') == 1) {    # See https://support.google.com/mail/answer/6254652?hl=ru
        my $value = $head->get('feedback-id');
        chomp($value);
        my ($key1, $key2, $key3, $sender_id) = split(/:/x, $value);
        $header->{'feedback_id'} = {key1 => $key1, key2 => $key2, key3 => $key3, sender_id => $sender_id};
    }
    elsif ($head->count('x-feedback-id') == 1) {
        my $value = $head->get('x-feedback-id');
        chomp($value);
        my ($key1, $key2, $key3, $sender_id) = split(/:/x, $value);
        $header->{'feedback_id'} = {key1 => $key1, key2 => $key2, key3 => $key3, sender_id => $sender_id};
    }

    # Headers List-Help, List-ID, List-Unsubscribe
    if ($head->count('list-unsubscribe') >= 1) {
        my $value = $head->get('list-unsubscribe');
        $value =~ s/\n//x;

        for my $val (split(/,/x, $value)) {
            chomp $val;
            $val = trim($val);
            $val =~ s/[\<\>]{1}//gx;
            if ($val =~ m/^http/x) {
                $header->{'list'}->{'unsubscribe'}->{'http'} = Mojo::URL->new($val);
            }
            elsif ($val =~ m/^mailto:/x) {
                $header->{'list'}->{'unsubscribe'}->{'email'} = $val;
            }
        }
    }

    if ($head->count('list-help') >= 1) {
        my $value = $head->get('list-help');
        $value =~ s/\n//x;
        $header->{'list'}->{'help'} = $value;
    }

    if ($head->count('list-id') >= 1) {
        my $value = $head->get('list-id');
        $value =~ s/\n//x;
        $header->{'list'}->{'id'} = $value;
    }

    # Headers X
    if ($head->as_string) {
        my $string_header = $head->as_string;

        my @headers;
        for my $header (split(/\n/x, $string_header)) {
            my ($key) = ($header =~ m/^(x\-[\w\-]+):/gix);
            push(@headers, $key) if (defined $key);
        }
        @headers = uniq(@headers);

        for my $key (@headers) {
            if ($key =~ m/x-priority/ix) {
                my $value = $head->get($key);
                ($value) = ($value =~ m/(\d{1})/x);
                $header->{'x_priority'} = $value;
                next;
            }
            elsif ($key =~ m/x-originating-ip/ix) {
                my $value = $head->get($key);
                $value =~ s/[\[\]]+//gx;
                chomp($value);
                $value = trim($value);
                $value =~ s/^\:\:ffff\://x if ($value =~ m/^\:\:ffff\:((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)/x);
                $value = Net::IP->new($value) or croak Net::IP::Error();
                $header->{'x_originating_ip'} = $value;
                next;
            }
            else {
                my @value = $head->get_all($key);
                chomp for (@value);
                $key = lc($key);
                $key =~ s/\-/_/gx;
                $header->{'headers'}->{$key} = \@value;
            }
        }
    }

    return $header;
}

1;

