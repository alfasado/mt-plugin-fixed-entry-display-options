package FixedDisplayOptions::Plugin;
use strict;

sub _set_entry_prefs {
    my ( $cb, $obj ) = @_;
    my $app = MT->instance();
    my $plugin = MT->component( 'FixedDisplayOptions' );
    require MT::Request;
    my $r = MT::Request->instance;
    if ( ref $app ne 'MT::App::CMS' ) {
        return 1;
    }
    if ( _is_admin() ) {
        if ( $app->mode eq 'save_entry_prefs' ) {
            my $_type = $app->param( '_type' );
            require MT::Permission;
            my @perms = MT::Permission->load( { blog_id => $obj->blog_id,
                                                author_id => { not => $obj->author_id } } );
            for my $p ( @perms ) {
                if ( $_type eq 'page' ) {
                    $p->page_prefs( $obj->page_prefs );
                } else {
                    $p->entry_prefs( $obj->entry_prefs );
                }
                $p->save or die $p->errstr;
            }
            if ( $_type eq 'page' ) {
                $plugin->set_config_value( 'page_prefs', $obj->page_prefs ,'blog:' . $obj->blog_id );
            } else {
                $plugin->set_config_value( 'entry_prefs', $obj->entry_prefs ,'blog:' . $obj->blog_id );
            }
        }
    }
    if ( $obj->blog_id ) {
        my $permissions = $obj->permissions;
        return 1 if $r->cache( 'cache_permission:' . $obj->id );
        $r->cache( 'cache_permission:' . $obj->id, 1 );
        if ( ( $permissions !~ /\'administer_website\'/ ) &&
            ( $permissions !~ /\'administer_blog\'/ ) ) {
            my $page_prefs = $plugin->get_config_value( 'page_prefs', 'blog:' . $obj->blog_id );
            my $entry_prefs = $plugin->get_config_value( 'entry_prefs', 'blog:' . $obj->blog_id );
            my $do;
            if ( $page_prefs ) {
                if ( $obj->page_prefs ne $page_prefs ) {
                    $obj->page_prefs( $page_prefs );
                    $do = 1;
                }
            }
            if ( $entry_prefs ) {
                if ( $obj->entry_prefs ne $entry_prefs ) {
                    $obj->entry_prefs( $entry_prefs );
                    $do = 1;
                }
            }
            if ( $do ) {
                $obj->save or die $obj->errstr;
            }
        }
    }
    return 1;
}

sub _hide_entry_prefs {
    my ( $cb, $app, $tmpl ) = @_;
    if (! _is_admin() ) {
        my $show_display_options = quotemeta( '<$mt:setvar name="show_display_options_link" value="1"$>' );
        $$tmpl =~ s/$show_display_options//s;
        my $css =<<CSS;
<mt:setvarblock name="html_head" append="1">
<style type="text/css">
#display-options-widget {display:none;}
</style>
</mt:setvarblock>
CSS
        $$tmpl = $css . $$tmpl;
    }
}

sub _is_admin {
    my $app = MT->instance();
    my $perm = $app->user->is_superuser;
    if (! $perm ) {
        if ( $app->blog ) {
            my $class;
            if ( MT->version_number < 5 ) {
                $class = 'blog';
            } else {
                $class = $app->blog->class;
            }
            my $permission = 'can_administer_' . $class;
            $perm = $app->user->permissions( $app->blog->id )->$permission;
        }
    }
    return $perm;
}

1;