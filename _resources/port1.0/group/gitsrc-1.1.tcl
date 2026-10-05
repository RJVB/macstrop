# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# This PortGroup accommodates projects hosted on GitHub or providers running compatible software

PortGroup gitmods 1.0

options gitsrc.scheme gitsrc.provider gitsrc.author gitsrc.project gitsrc.version gitsrc.tag_prefix gitsrc.tag_suffix

default gitsrc.scheme   {https}
default gitsrc.provider {github.com}

proc gitsrc.project_url {} {
    global gitsrc.scheme gitsrc.provider gitsrc.author gitsrc.project
    if {${gitsrc.author} ne "" && "${gitsrc.author}" ne "{}"} {
        return "${gitsrc.scheme}://${gitsrc.provider}/${gitsrc.author}/${gitsrc.project}"
    } else {
        return "${gitsrc.scheme}://${gitsrc.provider}/${gitsrc.project}"
    }
}

options gitsrc.homepage
default gitsrc.homepage {[gitsrc.project_url]}

options gitsrc.raw
default gitsrc.raw {https://raw.githubusercontent.com/${gitsrc.author}/${gitsrc.project}}

# Later code assumes that gitsrc.master_sites is a simple string, not a list.
options gitsrc.master_sites
default gitsrc.master_sites {[gitsrc.get_master_sites]}

proc gitsrc.get_master_sites {} {
    global gitsrc.tarball_from gitsrc.homepage git.branch gitsrc.provider fetch.type
    if {${gitsrc.provider} ne "github.com"} {
        fetch.type git
        ui_debug "github 1.1 PG : not fetching from github.com so forcing git fetching"
        return ""
    }
    switch -- ${gitsrc.tarball_from} {
        archive {
            # FIXME: Generate a more specific URL. When a branch and tag
            # share the same name, this will fail to resolve correctly.
            #
            # See:
            # https://trac.macports.org/ticket/70652
            # https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives#source-code-archive-urls
            return ${gitsrc.homepage}/archive/${git.branch}
        }
        downloads {
            # GitHub no longer hosts downloads on their servers.
            return macports_distfiles
        }
        tarball {
            global gitsrc.author gitsrc.project
            return https://codeload.github.com/${gitsrc.author}/${gitsrc.project}/legacy.tar.gz/${git.branch}?dummy=
        }
        default {
            # default to 'releases'
            return ${gitsrc.homepage}/releases/download/${git.branch}
        }
    }
}

options gitsrc.tarball_from
default gitsrc.tarball_from releases
option_proc gitsrc.tarball_from gitsrc.handle_tarball_from
proc gitsrc.handle_tarball_from {option action args} {
    if {${action} eq "set"} {
        switch ${args} {
            archive -
            downloads -
            releases -
            tarball {}
            tags {
                return -code error "the value \"tags\" is deprecated for gitsrc.tarball_from. Please use \"tarball\" instead."
            }
            default {
                return -code error "invalid value \"${args}\" for gitsrc.tarball_from"
            }
        }
    }
}

options gitsrc.livecheck.branch
default gitsrc.livecheck.branch master

options gitsrc.livecheck.regex
default gitsrc.livecheck.regex {(\[^"]+)}
#" (This is so certain editors see a closing double-quote)

proc gitsrc.setup {gh_author gh_project gh_version {gh_tag_prefix ""} {gh_tag_suffix ""}} {
    global gitsrc.author gitsrc.project gitsrc.version gitsrc.tag_prefix gitsrc.tag_suffix \
           gitsrc.homepage gitsrc.master_sites gitsrc.livecheck.branch PortInfo fetch.type

    gitsrc.author           ${gh_author}
    gitsrc.project          ${gh_project}
    gitsrc.version          ${gh_version}
    gitsrc.tag_prefix       ${gh_tag_prefix}
    gitsrc.tag_suffix       ${gh_tag_suffix}

    if {![info exists PortInfo(name)]} {
        name                ${gitsrc.project}
    }

    version                 ${gitsrc.version}
    default homepage        ${gitsrc.homepage}
    git.url                 ${gitsrc.homepage}.git
    git.branch              [join ${gitsrc.tag_prefix}]${gitsrc.version}[join ${gitsrc.tag_suffix}]
    default master_sites    {${gitsrc.master_sites}}
    if {${fetch.type} ne "git"} {
        distname            ${gitsrc.project}-${gitsrc.version}
    } else {
        distname            ${gitsrc.project}-git
    }

    default extract.rename  {[expr {${gitsrc.tarball_from} in {archive tarball} && [llength ${extract.only}] == 1}]}

    # If the version is composed entirely of hex characters, and is at least 7
    # characters long, and is not exactly 8 decimal digits (which might be a
    # version in YYYYMMDD format), and no tag prefix or suffix is provided, then
    # assume we are using a commit hash and livecheck commits; otherwise
    # livecheck tags.
    if {[join ${gitsrc.tag_prefix}] eq "" && \
        [join ${gitsrc.tag_suffix}] eq "" && \
        [regexp "^\[0-9a-f\]{7,}\$" ${gitsrc.version}] && \
        ![regexp "^\[0-9\]{8}\$" ${gitsrc.version}]} {
        default livecheck.type  git
        default livecheck.url   {${git.url}}
        default gitsrc.tarball_from archive
    } else {
        livecheck.type          regex
        default livecheck.url   {${gitsrc.homepage}/tags}
        default livecheck.regex {[list archive/refs/tags/[quotemeta [join ${gitsrc.tag_prefix}]][join ${gitsrc.livecheck.regex}][quotemeta [join ${gitsrc.tag_suffix}]]\\.tar\\.gz]}
    }
    default livecheck.branch    {${gitsrc.livecheck.branch}}
    livecheck.version           ${gitsrc.version}
}
