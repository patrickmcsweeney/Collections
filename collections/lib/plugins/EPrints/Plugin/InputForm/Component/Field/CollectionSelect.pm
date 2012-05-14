package EPrints::Plugin::InputForm::Component::Field::CollectionSelect;

use EPrints;
use EPrints::Plugin::Collection;
use EPrints::Plugin::InputForm::Component::Field;
@ISA = ( 'EPrints::Plugin::InputForm::Component::Field' );

use Unicode::String qw(latin1);
use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = 'Collection Select';
	$self->{visible} = 'all';
	$self->{visdepth} = 1;

	return $self;
}

sub update_from_form
{
	my( $self, $processor ) = @_;

	my $collection = $self->{dataobj};
	my $field = $self->{config}->{field};

	my $ibutton = $self->get_internal_button;

	if( $ibutton eq 'add_selected' )
	{
		my @params = $self->{session}->param;
		my @eprints_to_add = [];
		foreach( @params )
		{
			if( $_ =~ /^_add_(\d+)$/ )
			{
				$collection->add_to_collection( $1 );
			}
		}
	}

	if( $ibutton =~ /^(.+)_add$/ )
	{
		my $eprintid = $1;
		return unless( defined $eprintid );

		my $items = $self->{dataobj}->get_value( $field->get_name );

		my $exists = 0;
		foreach( @$items )
		{
			if( $_->{uri} eq $eprintid )
			{
				$exists = 1;
				last;
			}
		}

		if( $exists )
		{
			return;
		}

		push @$items, { type => 'http://purl.org/dc/terms/hasPart', uri => $eprintid };
		$self->{dataobj}->set_value( $field->get_name, $items );
		$self->{dataobj}->commit;
	}

	if( $ibutton =~ /^(.+)_remove$/ )
	{
		my $eprint_to_remove = $1;
		$collection->remove_from_collection( $eprint_to_remove ) if( defined $eprint_to_remove );
	}

	return;
}

sub render_title
{
	my( $self ) = @_;
	
	return $self->html_phrase( 'title' );
}

sub render_content
{
	my( $self, $surround ) = @_;

	my $session = $self->{session};
	my $field = $self->{config}->{field};
	my $eprint = $self->{workflow}->{item};

	my $page = $session->make_element( 'div' );
	$page->appendChild( $session->make_element( 'input', id=>'rel_path', type=>'hidden', value=>$session->get_repository->get_conf( 'rel_path' ) ) );
	$page->appendChild( $session->make_element( 'input', id=>'collection_eprintid', type=>'hidden', value=>$eprint->get_id ) );
	$page->appendChild( $session->make_element( 'input', id=>'fieldname', type=>'hidden', value=>$field->get_name ) );

	my $blacklist = $eprint->get_blacklist( $field->get_name );

	$page->appendChild( _render_selected_eprints( $session, $eprint, $field->get_name, $blacklist ) );
	
	my $box = $session->make_element( 'div', 'align'=>'center', class=>'ep_no_js' );
	my $pane = $session->make_element( 'div', class=>'ep_cs_nojs_pane' );
	$pane->appendChild( $self->html_phrase( 'no_js_instructions' ) );
	$pane->appendChild( $session->make_element( 'br' ) );
	$pane->appendChild( $session->render_button( name=>'_internal_'.$self->{prefix}.'_add_selected',
						value=>$self->html_phrase( 'add_all_resources' ),
						class=>'ep_form_internal_button' ) );
	$box->appendChild( $pane );
	$page->appendChild( $box );

	my $tabs = [ 'search', 'userdeposits' ];

	if( EPrints::Plugin::Collection::my_bookmarks_installed )
	{
		push @{$tabs}, 'bookmarks';
	}
	
	my $labels = {};
	my $links = {};
	my $panels = $session->make_element( 'div', id=>$self->{prefix}.'_items_panels', class=>'ep_tab_panel' );
	my $current = $tabs->[0];
	
	foreach my $tab ( @$tabs )
	{
		$labels->{$tab} = $self->html_phrase( 'tab_'.$tab );
		$links->{$tab} = '';
		
		my $new_panel = $session->make_element(
			'div',
			class=>($tab eq $current ? '' : 'ep_no_js'),
			id=>$self->{prefix}.'_items_panel_'.$tab );
		my $func_call = '_render_'.$tab.'_tab';
		if ( defined \&$func_call )
		{
			$new_panel->appendChild( $self->$func_call( $blacklist ) );
		}

		$panels->appendChild( $new_panel );
	}

	my $tab_block = $session->make_element( 'div', class=>'ep_only_js' );
	my $tab_set = $session->render_tabs(
			id_prefix=>$self->{prefix}.'_items',
			current=>$current,
			tabs=>$tabs,
			labels=>$labels,
			links=>$links );
	$tab_block->appendChild( $tab_set );
	$page->appendChild( $tab_block );

	$page->appendChild( $panels );
	
	return $page;
}

sub _render_working_folder
{
	my( $self, $blacklist ) = @_;
	
	my $session = $self->{session};
	my $user = $session->{current_user};
	
	my %opts;
	$opts{'ids'} = $user->get_user_related_eprintids( $session );
	$opts{'session'} = $session;
	$opts{'dataset'} = $self->{dataset};
	my $list = EPrints::List->new( %opts );

	my $div = $session->make_element( 'div', id=>'tab_workingfolder_content' );
	$div->appendChild( $self->html_phrase( 'folder_heading' ) );

	my $content = $session->make_element( 'div', class=>'ep_cs_pane' );
	$div->appendChild( $content );
	
	if( !$list->count )
	{
		$content->appendChild( $self->html_phrase( 'no_working_folder_items' ) );
		return $div;
	}

	$content->appendChild( _render_checkbox_table( $session, $list, $blacklist ) );

	return $div;
}

sub _render_bookmarks_tab
{
	my( $self, $blacklist ) = @_;

	my $session = $self->{session};
	my $user = $session->current_user;

	my %opts;
	$opts{'ids'} = $user->get_bookmarks_ids( $session );
	$opts{'session'} = $session;
	$opts{'dataset'}= $self->{dataset};

	my $list = EPrints::List->new( %opts );

	my $list_all_collections = _get_all_collections( $session );

	$list = $list->remainder( $list_all_collections );

	my $div = $session->make_element( 'div', id=>'tab_bookmarks_content' );
	$div->appendChild( $self->html_phrase( 'bookmarks_heading' ) );

	my $content = $session->make_element( 'div', class=>'ep_cs_pane' );
	$div->appendChild( $content );

	if( !$list->count )
	{
		$content->appendChild( $self->html_phrase( 'no_bookmarks' ) );
		return $div;
	}

	$content->appendChild( _render_checkbox_table( $session, $list, $blacklist ) );

	return $div;
}

sub _render_userdeposits_tab
{
	my( $self, $blacklist ) = @_;

	my $session = $self->{session};

	my $div = $session->make_element( 'div', id=>'tab_userdeposits_content' );
	$div->appendChild( $self->html_phrase( 'your_deposits_heading' ) );
	
	my $results_div = $session->make_element( 'div', class=>'ep_cs_pane' );
	$div->appendChild( $results_div );
	my $ds = $session->get_repository->get_dataset( 'archive' );
	my $list = $session->current_user->get_eprints( $ds );
	$list = $list->reorder( '-status_changed' );

	my $list_all_collections = _get_all_collections( $session );
	$list = $list->remainder( $list_all_collections );

	if( !$list->count )
	{
		$results_div->appendChild( $self->html_phrase( 'no_deposits' ) );
	}
	else
	{
		$results_div->appendChild( _render_checkbox_table( $session, $list, $blacklist ) );
	}

	return $div;
}

sub _render_selected_eprints
{
	my( $session, $eprint, $fieldname, $blacklist ) = @_;

	my $div = $session->make_element( 'div', id=>'selected_eprints', style=>'padding: 5px;border: 1px solid #c5dcff;background-color: #e6eeff;' );
	$div->appendChild( $session->html_phrase( 'Plugin/InputForm/Component/Field/CollectionSelect:current_selected' ) );

	my $items = $eprint->get_value( $fieldname );
	if( !EPrints::Utils::is_set( $items ) )
	{
		$div->appendChild( $session->html_phrase( 'Plugin/InputForm/Component/Field/CollectionSelect:nothing_selected' ) );
		return $div;
	}

	my @eprintids;
	foreach( @$items )
	{
		push @eprintids, $_->{uri};
	}

	my %opts;
	$opts{'ids'} = \@eprintids;
	$opts{'session'} = $session;
	$opts{'dataset'} = $session->get_repository->get_dataset( 'archive' );
	my $list = EPrints::List->new( %opts );

	$div->appendChild( _render_checkbox_table( $session, $list, $blacklist ) );

	return $div;
}

sub _do_search
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $ds = $session->get_repository->get_dataset( 'archive' );
	my $sconf = $session->get_repository->get_conf( 'search' )->{simple};
	my $fields = $sconf->{search_fields}->[0]->{meta_fields};
	my @meta_fields;
	foreach my $fieldname ( @$fields )
	{
		push @meta_fields, EPrints::Utils::field_from_config_string( $ds, $fieldname );
	}

	my $searchexp = new EPrints::Search(
		session=>$session,
		dataset=>$ds,
		custom_order=>'title' );
	$searchexp->add_field(
		\@meta_fields,
		$self->{search},
		'IN',
		'ALL' );
	my $results = $searchexp->perform_search;
	my $all_collections = _get_all_collections( $session );

	return $results->remainder( $all_collections );
}

sub _render_search_box
{
	my( $self ) = @_;

	my $prefix = $self->{prefix};
	my $session = $self->{session};
	my $field = $self->{config}->{field};

	my $div = $session->make_element( 'div', style=>'padding: 5px;' );
	$div->appendChild( $self->html_phrase( 'search_heading' ) );

	my $bar = $self->html_phrase(
		$field->get_name.'_search_bar',
		input=>$session->render_noenter_input_field(
			class=>'ep_form_text',
			name=>$prefix.'_searchtext',
			id=>'ep_cs_searchbox',
			type=>'text',
			value=>$self->{search},
			onKeyPress=>'return EPJS_enter_click( event, \'_internal_'.$prefix.'_search\' )' ),
		search_button=>$session->render_button(
			name=>'_internal_'.$prefix.'_search',
			class=>'ep_form_internal_button',
			id=>'_internal_'.$prefix.'_search',
			value=>$self->phrase( 'search_search_button' ) ),
		clear_button=>$session->render_button(
			name=>'_internal_'.$prefix.'_clear',
			class=>'ep_form_internal_button',
			value=>$self->phrase( 'search_clear_button' ) ) );

	$div->appendChild( $bar );

	return $div;
}

sub _render_search_tab
{
	my( $self, $blacklist ) = @_;
	
	my $session = $self->{session};
	my $force_search = defined $session->param( $self->{prefix}.'_searchtext' );
	my $div = $session->make_element( 'div', id=>'tab_search_content' );
	
	if( $session->internal_button_pressed || $force_search )
	{
		my $ibutton = $self->get_internal_button;
		
		if( $ibutton eq 'search' || $force_search )
		{
			$self->{search} = $session->param( $self->{prefix}.'_searchtext' );
		}
		
		if( $ibutton eq 'clear' )
		{
			delete $self->{search};
		}
	}

	if( $self->{search} eq '' )
	{
		delete $self->{search};
	}

	$div->appendChild( $self->_render_search_box );
	$div->appendChild( $self->html_phrase( 'search_results_heading' ) );

	my $results_div = $session->make_element( 'div', class=>'ep_cs_pane' );
	$div->appendChild( $results_div );

	if( $self->{search} )
	{
		my $search_store = $session->render_hidden_field(
			$self->{prefix}.'_searchstore',
			$self->{search} );
		$results_div->appendChild( $search_store );

		my $results = $self->_do_search;

		if( !$results->count )
		{
			$results_div->appendChild( $self->html_phrase(
				'search_no_matches' ) );
		}
		else
		{
			$results_div->appendChild( _render_checkbox_table( $session, $results, $blacklist ) );
		}
	}

	return $div;
}

# Params:
# table_class: Class for the table
# subject_class: Class for the subject cell
# button_class: Class for the button cell
# button_text: Text for the button
# button_id: Postfix for the button name
# subjects: Array of subjects
# hide_selected: If 1, hides any aleady selected subjects

sub get_state_params
{
	my( $self ) = @_;

	my $params = '';
	foreach my $id ( $self->{prefix}.'_searchstore', $self->{prefix}.'_searchtext' )
	{
		my $v = $self->{session}->param( $id );
		next unless defined $v;
		$params .= "&$id=$v";
	}

	if( $self->{session}->param( '_internal_'.$self->{prefix}.'_search' ) )
	{
		$params .= '&'.$self->{prefix}.'_internal_action=search';
	}
	elsif( $self->{session}->param( '_internal_'.$self->{prefix}.'_clear' ) )
	{
		$params .= '&'.$self->{prefix}.'_internal_action=clear';
	}

	return $params;
}

sub _render_checkbox_table
{
	my( $session, $list, $blacklist ) = @_;

	my( $table, $tr, $td );
	$table = $session->make_element( 'table', class=>'ep_cs_checktable', cellpadding=>'0', cellspacing=>'0', border=>'0', width=>'100%' );

	my $is_first = 1;
	foreach my $rec ( $list->get_records )
	{
		$tr = $session->make_element( 'tr' );
		$table->appendChild( $tr );

		my $extra_class = $is_first ? "ep_cs_checktable_first" : "";

		$td = $session->make_element( 'td', width=>'90%', class=>"ep_cs_checktable_left $extra_class" );
		$tr->appendChild( $td );
		$td->appendChild( $rec->render_citation( 'collection_select' ) );

		$td = $session->make_element( 'td', width=>'10%', class=>"ep_cs_checktable_right $extra_class" );
		$tr->appendChild( $td );

		if( $blacklist->{$rec->get_id} )
		{
			$td->appendChild( $session->make_element( 'input', id=>'_add_'.$rec->get_id, class=>'ep_cs_checkbox', type=>'checkbox', checked=>'yes', name=>'_add_'.$rec->get_id ) );
		}
		else
		{
			my $check = $session->make_element( 'input', id=>'_add_'.$rec->get_id, class=>'ep_cs_checkbox', type=>'checkbox', name=>'_add_'.$rec->get_id );
			$td->appendChild( $check );
		}
		
		$is_first = 0 if( $is_first );
	}

	return $table;
}

sub _get_all_collections
{
	my( $session ) = @_;
	
	my $ds = $session->get_repository->get_dataset( 'archive' );
	my $search_all_collections = new EPrints::Search(
		session=>$session,
		dataset=>$ds,
		custom_order=>'title' );

	$search_all_collections->add_field(
		$ds->get_field( 'type' ),
		'collection',
		'IN',
		'ALL' );
	
	return $search_all_collections->perform_search;
}
1;
