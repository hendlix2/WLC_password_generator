#Script generates a password and qrcode and sents it via email
#Generated 9.Jan 2024 V1.00 by Peter Hendlinger
#
#!/usr/bin/perl

#use strict;
#use warnings;
use Crypt::URandom;
use MIME::Lite;
use DateTime;
use File::Temp;

# Funktion zur Generierung eines sicheren Passworts
sub generate_password {
    my ($length) = @_;

    my @characters = ('a'..'z', 'A'..'Z', '0'..'9', '-', '_', '+', '!', '&');
    my $password = '';

    while (length($password) < $length) {
        my $temp_char = $characters[int(rand(scalar @characters))];
        $password .= $temp_char unless $password =~ /\Q[$temp_charO0Il1]\E/;
    }

    return $password;
}

# Funktion zur Generierung eines QR-Codes
sub generate_qr_code {
    my ($text, $filename) = @_;
    my $qrcode_command = "qrencode -t PNG -o $filename -s 8 '$text'";
    system($qrcode_command);
}

# E-Mail-Konfiguration
my $to_address = 'to@mail.com';
my $from_address = 'from@email.com';

# Generiere ein sicheres Passwort
my $new_password = generate_password(12);

# Output und Speichern des Passworts
print "Generated Password: $new_password\n";
my $file = 'passwords.txt';
open my $fh, '>>', $file or die "Could not open file '$file' $!";
print $fh "Date: " . localtime() . " Password: $new_password\n";
close $fh;

# Generiere und speichere QR-Code
my $qr_code_filename = '/home/peter/chatcgt/generate_password/android.png';
generate_qr_code("WIFI:T:WPA;S:gaeste;P:$new_password;H:false;", $qr_code_filename);
print "QR Code generated and saved as $qr_code_filename\n";

# Senden der E-Mail über das Mail-Relay
my $msg = MIME::Lite->new(
    From    => $from_address,
    To      => $to_address,
    Subject => get_subject(),
    Type    => 'multipart/mixed'
);

# Hinzufügen des Passworts zum E-Mail-Text
my $email_body = "<html>
<head>
    <style>
        body {
            font-family: Arial, sans-serif;
        }
        .container {
            max-width: 600px;
            margin: auto;
        }
        .logo {
            max-width: 100%;
        }
    </style>
</head>
<body>
    <div class='container'>
        <h1>Guest WLAN Password for " . get_subject() . "</h1>
        <p>Password: $new_password</p>
        <img src='cid:android.png' alt='QR Code'>
        <p>Last updated by user date: " . localtime() . "</p>
    </div>
</body>
</html>";

$msg->attach(
    Type => 'image/png',
    Path => $qr_code_filename,
    Filename => 'android.png',
    Disposition => 'inline',
    Id => 'android.png',
);

$msg->attach(
    Type     => 'text/html',
    Data     => $email_body,
);

# Setze das Mail-Relay
$msg->send('sendmail', '/usr/sbin/sendmail -t -oi -oem -f ' . $from_address) or die "Unable to send email: $!\n";

print "QR Code emailed to $to_address\n";

# Hilfsfunktion zum Erhalten des korrekten Monats im Subject
sub get_subject {
    my $dt = DateTime->now->add(months => 1);
    my $formatted_date = $dt->strftime('%B %Y');
    return $formatted_date;
}
