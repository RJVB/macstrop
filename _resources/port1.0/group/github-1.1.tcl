# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# This PortGroup accommodates projects hosted at GitHub.
#
# Documentation:
# https://guide.macports.org/#reference.portgroup.github
#
# Documentation (sources):
# https://github.com/macports/macports-guide/blob/master/guide/xml/portgroup-github.xml

options github.author github.project github.version github.tag_prefix github.tag_suffix

options github.homepage
default github.homepage {https://github.com/${github.author}/${github.project}}

options github.raw
default github.raw {https://raw.githubusercontent.com/${github.author}/${github.project}}

# Later code assumes that github.master_sites is a simple string, not a list.
options github.master_sites
default github.master_sites {[github.get_master_sites]}

proc github.get_master_sites {} {
    global github.tarball_from github.homepage git.branch
    switch -- ${github.tarball_from} {
        archive {
            # FIXME: Generate a more specific URL. When a branch and tag
            # share the same name, this will fail to resolve correctly.
            #
            # See:
            # https://trac.macports.org/ticket/70652
            # https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives#source-code-archive-urls
            return ${github.homepage}/archive/${git.branch}
        }
        downloads {
            # GitHub no longer hosts downloads on their servers.
            return macports_distfiles
        }
        tarball {
            global github.author github.project
            return https://codeload.github.com/${github.author}/${github.project}/legacy.tar.gz/${git.branch}?dummy=
        }
        default {
            # default to 'releases'
            return ${github.homepage}/releases/download/${git.branch}
        }
    }
}

options github.tarball_from
default github.tarball_from releases
option_proc github.tarball_from github.handle_tarball_from
proc github.handle_tarball_from {option action args} {
    if {${action} eq "set"} {
        switch ${args} {
            archive -
            downloads -
            releases -
            tarball {}
            tags {
                return -code error "the value \"tags\" is deprecated for github.tarball_from. Please use \"tarball\" instead."
            }
            default {
                return -code error "invalid value \"${args}\" for github.tarball_from"
            }
        }
    }
}

options github.livecheck.branch
default github.livecheck.branch master

options github.livecheck.regex
default github.livecheck.regex {(\[^"]+)}

options git.shallow_since
default git.shallow_since {}

proc github.setup {gh_author gh_project gh_version {gh_tag_prefix ""} {gh_tag_suffix ""}} {
    global github.author github.project github.version github.tag_prefix github.tag_suffix \
           github.homepage github.master_sites github.livecheck.branch PortInfo

    github.author           ${gh_author}
    github.project          ${gh_project}
    github.version          ${gh_version}
    github.tag_prefix       ${gh_tag_prefix}
    github.tag_suffix       ${gh_tag_suffix}

    if {![info exists PortInfo(name)]} {
        name                ${github.project}
    }

    version                 ${github.version}
    default homepage        ${github.homepage}
    git.url                 ${github.homepage}.git
    git.branch              [join ${github.tag_prefix}]${github.version}[join ${github.tag_suffix}]
    default master_sites    {${github.master_sites}}
    distname                ${github.project}-${github.version}

    default extract.rename  {[expr {${github.tarball_from} in {archive tarball} && [llength ${extract.only}] == 1}]}

    # If the version is composed entirely of hex characters, and is at least 7
    # characters long, and is not exactly 8 decimal digits (which might be a
    # version in YYYYMMDD format), and no tag prefix or suffix is provided, then
    # assume we are using a commit hash and livecheck commits; otherwise
    # livecheck tags.
    if {[join ${github.tag_prefix}] eq "" && \
        [join ${github.tag_suffix}] eq "" && \
        [regexp "^\[0-9a-f\]{7,}\$" ${github.version}] && \
        ![regexp "^\[0-9\]{8}\$" ${github.version}]} {
        livecheck.type          regexm
        default livecheck.url   {${github.homepage}/commits/${github.livecheck.branch}.atom}
        default livecheck.regex {<id>tag:github.com,2008:Grit::Commit/(\[0-9a-f\]{[string length ${github.version}]})\[0-9a-f\]*</id>}
        default github.tarball_from archive
    } else {
        livecheck.type          regex
        default livecheck.url   {${github.homepage}/tags}
        default livecheck.regex {[list archive/refs/tags/[quotemeta [join ${github.tag_prefix}]][join ${github.livecheck.regex}][quotemeta [join ${github.tag_suffix}]]\\.tar\\.gz]}
    }
    livecheck.version       ${github.version}
}

rename portfetch::gitfetch portfetch::gitfetch_stock
pre-fetch {
    ui_debug "github-1.0 PG overloaded the gitfetch procedure!"
}
proc portfetch::gitfetch {args} {
    global worksrcpath patchfiles \
           git.url git.branch git.cmd git.shallow_since

    set options "--progress --recurse-submodules"
    if {${git.shallow_since} ne {}} {
        append options " --shallow-since ${git.shallow_since} --shallow-submodules"
    } elseif {${git.branch} eq ""} {
        # if we're just using HEAD, we can make a shallow repo
        append options " --depth=1 --shallow-submodules"
    }
    set cmdstring "${git.cmd} clone $options ${git.url} [shellescape ${worksrcpath}] 2>&1"
    ui_debug "Executing: $cmdstring"
    if {[catch {system $cmdstring} result]} {
        return -code error [msgcat::mc "Git clone failed"]
    }

    if {${git.branch} ne ""} {
        set env "GIT_DIR=[shellescape ${worksrcpath}/.git] GIT_WORK_TREE=[shellescape ${worksrcpath}]"
        set cmdstring "$env ${git.cmd} checkout -q ${git.branch} 2>&1"
        ui_debug "Executing $cmdstring"
        if {[catch {system $cmdstring} result]} {
            return -code error [msgcat::mc "Git checkout failed"]
        }
    }

    if {[info exists patchfiles]} {
        return [portfetch::fetchfiles]
    }

    return 0
}
