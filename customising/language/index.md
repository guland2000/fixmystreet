---
layout: page
title: Changing the language
---

# Changing the language

<p class="lead">Here we explain how to change what language is displayed on 
FixMyStreet, how to contribute your own if we don&rsquo;t have yours, and how to
run a site in multiple languages. <strong>Work in progress.</strong></p>

## Setup

The translations for most FixMyStreet strings are stored as standard 
<a href="{{ "/glossary/#gettext" | relative_url }}" class="glossary__link">gettext</a>
files, in `FixMyStreet.po` files under `locale/<lang>/LC_MESSAGES/`. A
few full pages, such as the FAQ, and emails, are stored separately in the
templates directory and should be translated by creating new templates in your
cobrand.


Firstly, set the
<code><a href="{{ "/customising/config/#languages" | relative_url }}">LANGUAGES</a></code>
configuration option to the languages your site uses. This is an array of
strings specifying what language or languages your installation uses. For
example, if your site is available in English, French, and German, you would
have:

    LANGUAGES:
        - 'en-gb,English,en_GB'
        - 'fr,French,fr_FR'
        - 'de,German,de_DE'

This would then set up things appropriately to use the relevant language files
you have made.

You must make sure that the locale for any language you use is installed on the
server in order for the translations to work properly. On Debian, you can alter
`/etc/locale.gen` and run `sudo locale-gen`. On Ubuntu, you can just run `sudo
locale-gen <LOCALE_NAME>`.

## Seeing the site in your language

By default, FixMyStreet is set up so visiting a hostname starting with the
two-letter language code will use that language; otherwise it will detect based
upon the browser. If you have used the install script on a clean server, or the
AMI, you should be able to visit your domain with a language code at the start
by default.

Using the example above `http://fr.fixmystreet.com/` would display the
French translation and `http://de.fixmystreet.com/` would display the
German translation. If no language is specified in the URL, or an
unsupported code is used then it will fall back to the language
negotiated by the browser. If that language is not available,
the first language listed in the `LANGUAGES` configuration option
will be displayed.

Note that this method only supports two letter language codes. This
means you cannot use `sv-se` format strings to distingish regional
variants in the hostname. However, the first part of the language string
does not need to be an official language code so you can use it to allow
regional variants, e.g:

    LANGUAGES:
        - 'sv,Svenska,sv_SE'
        - 'sf,Svenska,sv_FI'

`http://sv.fixmystreet.com` would dsplay `sv_SE` and
`http://sf.fixmystreet.com` would display `sv_FI`.

These language links can be used for adding a language switcher to the
site. For example, a basic two language switcher:

    [% IF lang_code == 'fr' %]
        <li><a href="https://en.[% c.cobrand.base_host %][% c.req.uri.path_query %]">English</a></li>
    [% ELSE %]
        <li><a href="https://fr.[% c.cobrand.base_host %][% c.req.uri.path_query %]">Français</a></li>
    [% END %]

## Contributing a translation

If we don't already have a translation for the language you want, please do
consider contributing one :) You can use our repository on
[Transifex](https://www.transifex.com/projects/p/fixmystreet/),
or translate the `.po` files directly using a local program such as
[PoEdit](http://www.poedit.net/).

The templates use the `loc` function to pass strings to gettext for
translation. If you create or update a `.po` file, you will need to run the
`commonlib/bin/gettext-makemo` script to compile these files into the machine
readable format used by the site.

## Translating the FAQ

The FAQ pages do not use gettext so need to be translated separately by
creating a new template under your co-brand, e.g for a German
translation:

  templates/web/<co-brand>/about/faq-de.html

For other languages the file should be `faq-<lang>.html`. If there is
not a translated template it will fall back to `faq.html`.