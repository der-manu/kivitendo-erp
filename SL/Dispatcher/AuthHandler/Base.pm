package SL::Dispatcher::AuthHandler::Base;

use strict;
use parent qw(Rose::Object);

use Encode ();
use MIME::Base64 ();

use SL::Layout::Dispatcher;

sub _env_var_for_header {
  my ($header) = @_;

  $header =~ s{-}{_}g;
  return $ENV{'HTTP_' . uc($header)};
}

sub _parse_http_basic_auth {
  my ($self) = @_;

  my $cfg = $::lx_office_conf{'authentication/http_basic'};

  return unless $cfg && $cfg->{enabled};

  # See RFC 7617.

  # Requires that the server passes the 'Authorization' header as the
  # environment variable 'HTTP_AUTHORIZATION'. Example code for
  # Apache:

  # SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1

  my $data = _env_var_for_header('Authorization');

  return unless ($data // '') =~ m{^basic +(.+)}i;

  $data = Encode::decode('utf-8', MIME::Base64::decode($1));

  return unless $data =~ m{(.+?):(.+)};

  return ($1, $2);
}

sub _parse_http_headers_auth {
  my ($self) = @_;

  my $cfg = $::lx_office_conf{'authentication/http_headers'};

  return unless $cfg && ($::lx_office_conf{'authentication'}->{module} =~ m{HTTPHeaders});

  foreach (qw(secret_header secret user_header client_id_header)) {
    next if $cfg->{$_};
    die 'config/kivitendo.conf: Missing parameter in "authentication/http_headers": ' . $_;
  }

  my $secret = _env_var_for_header($cfg->{secret_header}) // '';
  if ($secret ne $cfg->{secret}) {
    $::lxdebug->message(LXDebug->DEBUG2(), "_parse_http_headers_auth: bad secret sent by upstream server: $secret");
    return;
  }

  my $client_id = _env_var_for_header($cfg->{client_id_header});
  if (!$client_id) {
    $::lxdebug->message(LXDebug->DEBUG2(), "_parse_http_headers_auth: no client ID header found");
    return;
  }

  # $::auth->set_client();

  my $user = _env_var_for_header($cfg->{user_header});
  if (!$user) {
    $::lxdebug->message(LXDebug->DEBUG2(), "_parse_http_headers_auth: no user name header found");
    return;
  }

  $::lxdebug->message(LXDebug->DEBUG2(), "_parse_http_headers_auth: OK client $client_id user $user");

  return ($client_id, $user);
}

1;
