package SL::Model::Record;

use strict;

use SL::Locale::String qw(t8);


sub new {
  my ($class, $target_type, %flags) = @_;

  # target_type: der angeforderte typ
  # flags: zusätzliche informationen zu der behanldung (soll    )

  # (aus add) neues record mit vorbereitenden sachen wie transdate/reqdate
  #
  # rückgabe: neues objekt
  # fehlerfall: exception
}

sub new_from_workflow {
  my ($class, $source_objects, $target_type, %flags) = @_;

  # source: entweder das einzelne quellobjekt oder ein arrayref von quellobjekten.
  #   - wenn ein arrayref übergeben wurde muss der code testen ob die objekte alle subtype gleich sind und evtl customer/vendor gleich sind
  # target type: sollte ein subtype sein. wer das hier implementiert, sollte auch eine subtype registratur bauen in der man subtypes nachschlagen kann
  # flags: welche extra behandlungen sollen gemacht werden, z.B. record_links setzen

  # muss prüfen ob diese umwandlung korrekt ist
  # muss das entsprechende new_from in den objekten selber benutzen
  # und dann evtl nachbearbeitung machen (die bisher im controller stand)

  # new_from_workflow: (aus add_from_*) workflow umwandlung von bestehenden records

  # fehlerfall: exception aus unterliegendem code bubblen oder neue exception werfen
  # rückgabe: das neue objekt
}

# im Moment nur bei Aufträgen
sub increment_subversion {
  my ($class, $record, %flags) = @_;

  # erhöht die version des auftrags
  # setzt die neue auftragsnummer
  # legt OrderVersion objekt an
  # speichert
  #
  # return - nichts
  # fehlerfall: exception
}

sub delete {
  my ($class, $record, %params) = @_;

  my $errors = [];
  my $db = $record->db;

  $db->with_transaction(
    sub {
      my @spoolfiles = grep { $_ } map { $_->spoolfile } @{ SL::DB::Manager::Status->get_all(where => [ trans_id => $record->id ]) };
      $record->delete;
      my $spool = $::lx_office_conf{paths}->{spool};
      unlink map { "$spool/$_" } @spoolfiles if $spool;

      _save_history($record,'DELETED', \$params{history});

      1;
  }) || push(@{$errors}, $db->error);

  if (scalar @{ $errors} ){
    croak(t8('Error delete record'));
  };
  # das hier sollte der code sein der in sub delete aus den controllern liegt
  # nicht nur record->delete, sondern auch andere elemente aufräumen
  # spool aufräumen
  # status aufräumen
  # history eintrag
  #
  # return: nichts
  # fehler: exception
}

sub _save_history {
  my ($record, $addition, %history) = @_;

  my $number_type = $record->type =~ m{order} ? 'ordnumber' : 'quonumber';
  my $snumbers    = $number_type . '_' . $record->$number_type;

  SL::DB::History->new(
    trans_id    => $record->id,
    employee_id => SL::DB::Manager::Employee->current->id,
    what_done   => $record->type,
    snumbers    => $snumbers,
    addition    => $addition,
  )->save;
}
sub save {
  my ($class, $record, %params) = @_;

  # record: das zu speichernde objekt
  # params:
  #   - with_validity_token -> scope
  #   - delete custom shipto if empty
  #   - item_ids_to_delete
  #   - order version behandlung


  # muss linked_records aus converted_from_* erzeugen -> verschieben in after_save hooks
  # wenn aus quotation erstellt, muss beim speichern das angebot geschlossen werden
  # wenn aus lieferschein erstellt muss beim speichern delivered setzen (wenn in config aktiviert)
  # muss auch link requirement_specs machen (was tut das?)
  # set project in linked requirementspecs (nur aufträge -> flag)
  #
  # history einträge erstellen

  # rückgabe: nichts
  # fehler: exception
}

sub update_for_save_as_new {
  my ($class, $record, %params) = @_;

  # der übergebene beleg wurde mit new_from erstellt und muss nachbearbeitet werden:
  # - transadte, reqdate müssen überschrieben werden
  # - number muss überschrieben werden
  # - employee auf aktuellen setzen

  # return: nichts
  # fehler: exception
}


1;

__END__

=encoding utf-8

=head1 NAME

SL::Model::Record - shared computations for orders (Order), delivery orders (DeliveryOrder), invoices (Invoice) and reclamations (Reclamation)

=head1 SYNOPSIS



=head1 DESCRIPTION

=item C<delete>

deletes the whole record and put an entree in the history.
Expects a record with %params for history params{history} = \%history

=item C<_save_history>

Expects a record for id, addition for text (SAVED,...) and %history{snumber}

=head1 BUGS

None yet. :)

=head1 AUTHORS

