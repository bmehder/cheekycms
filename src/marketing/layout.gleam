//// The marketing site's HTML shell, styles, and favicon artwork.
////
//// Wraps the CMS-authored homepage body in a complete document. Content comes from
//// the homepage singleton; HTTP response headers and catalogue lookup belong to
//// `marketing/pages`.

import gleam/string

/// Wrap the CMS-authored homepage in its shared document shell.
pub fn html(title: String, description: String, body_html: String) -> String {
  let safe_title = escape(title)
  let safe_description = escape(description)

  "
  <!doctype html>
  <html lang='en'>
    <head>
      <meta charset='utf-8'>
      <meta name='viewport' content='width=device-width, initial-scale=1'>
      <meta name='description' content='" <> safe_description <> "'>
      <meta name='theme-color' content='#11100f'>
      <meta property='og:title' content='" <> safe_title <> "'>
      <meta property='og:description' content='" <> safe_description <> "'>
      <meta property='og:type' content='website'>
      <meta property='og:url' content='https://cheekycms.fly.dev/'>
      <meta name='twitter:card' content='summary'>
      <link rel='canonical' href='https://cheekycms.fly.dev/'>
      <link rel='icon' href='/favicon.svg' type='image/svg+xml'>
      <title>" <> safe_title <> "</title>
      <style>
        :root { color-scheme: dark; --ink: #f6f0e5; --muted: #aaa398; --paper: #11100f; --panel: #1a1816; --line: #34302c; --hot: #ff6b4a; --lime: #c8f169; }
        * { box-sizing: border-box; }
        html { scroll-behavior: smooth; }
        body { margin: 0; background: var(--paper); color: var(--ink); font: 16px/1.6 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
        a { color: inherit; }
        .wrap { width: min(1120px, calc(100% - 40px)); margin-inline: auto; }
        nav { display: flex; align-items: center; justify-content: space-between; padding-block: 24px; }
        .brand { display: flex; align-items: center; gap: 12px; text-decoration: none; font-weight: 800; letter-spacing: -.04em; }
        .mark { display: grid; place-items: center; width: 34px; height: 34px; border-radius: 9px; background: var(--hot); color: #11100f; transform: rotate(-4deg); }
        .navlinks { display: flex; gap: 22px; color: var(--muted); font-size: 14px; }
        .navlinks a:hover { color: var(--ink); }
        .navlinks { align-items: center; }
        .icon-link { display: inline-flex; align-items: center; justify-content: center; min-width: 32px; min-height: 32px; }
        .icon-link:focus-visible { outline: 2px solid var(--lime); outline-offset: 4px; border-radius: 4px; }
        .hero { padding: clamp(72px, 12vw, 150px) 0 90px; border-bottom: 1px solid var(--line); }
        .eyebrow { color: var(--lime); text-transform: uppercase; letter-spacing: .14em; font-size: 13px; font-weight: 700; }
        h1 { max-width: 900px; margin: 18px 0 28px; font: 800 clamp(52px, 9vw, 112px)/.9 ui-sans-serif, system-ui, sans-serif; letter-spacing: -.07em; }
        h1 em { color: var(--hot); font-style: normal; }
        .lede { max-width: 720px; color: #d0c9be; font: 21px/1.55 ui-sans-serif, system-ui, sans-serif; }
        .actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 36px; }
        .button { padding: 12px 18px; border: 1px solid var(--line); border-radius: 8px; text-decoration: none; font-weight: 700; }
        .button.primary { border-color: var(--hot); background: var(--hot); color: #17110f; }
        .button:hover { transform: translateY(-2px); }
        section { padding: 88px 0; border-bottom: 1px solid var(--line); }
        h2 { margin: 0 0 18px; font: 750 clamp(32px, 5vw, 56px)/1 ui-sans-serif, system-ui, sans-serif; letter-spacing: -.045em; }
        .section-intro { max-width: 700px; margin: 0 0 42px; color: var(--muted); font: 18px/1.6 ui-sans-serif, system-ui, sans-serif; }
        .demo { display: grid; grid-template-columns: 1fr 1fr; overflow: hidden; border: 1px solid var(--line); border-radius: 14px; background: var(--panel); }
        .code { min-width: 0; padding: 24px; }
        .code + .code { border-left: 1px solid var(--line); }
        .label { display: block; margin-bottom: 18px; color: var(--muted); font-size: 12px; letter-spacing: .12em; text-transform: uppercase; }
        pre { margin: 0; overflow-x: auto; color: #ded7ca; font: 13px/1.65 ui-monospace, SFMono-Regular, Menlo, monospace; white-space: pre-wrap; }
        .key { color: var(--lime); } .value { color: #ffad99; }
        .cards { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }
        .card { padding: 26px; border: 1px solid var(--line); border-radius: 12px; background: var(--panel); }
        .card strong { display: block; margin-bottom: 10px; color: var(--ink); font: 700 19px/1.3 ui-sans-serif, system-ui, sans-serif; }
        .card p { margin: 0; color: var(--muted); }
        .honest { display: grid; grid-template-columns: 1fr 1fr; gap: 70px; }
        .list { margin: 24px 0 0; padding: 0; list-style: none; color: #ccc5ba; }
        .list li { padding: 8px 0; border-bottom: 1px solid var(--line); }
        .yes li::before { content: '+ '; color: var(--lime); }
        .no li::before { content: '− '; color: var(--hot); }
        .aside { color: var(--muted); }
        .aside big { display: block; margin-bottom: 22px; color: var(--ink); font: 700 28px/1.25 ui-sans-serif, system-ui, sans-serif; }
        footer { display: flex; justify-content: space-between; gap: 24px; padding-block: 34px; color: var(--muted); font-size: 13px; }
        @media (max-width: 760px) { .demo, .honest { grid-template-columns: 1fr; } .code + .code { border-left: 0; border-top: 1px solid var(--line); } .cards { grid-template-columns: 1fr; } .navlinks a:first-child { display: none; } footer { flex-direction: column; } }
        @media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto; } .button:hover { transform: none; } }
      </style>
    </head>
    <body>
      <nav class='wrap' aria-label='Primary navigation'>
        <a class='brand' href='/'><span class='mark' aria-hidden='true'>C</span> CheekyCMS</a>
        <div class='navlinks'>
          <a href='#about'>What it is</a>
          <a href='/api'>Explore the API</a>
          <a class='icon-link' href='/reference/' aria-label='Gleam code documentation' title='Gleam code documentation'><svg aria-hidden='true' focusable='false' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='1.7' stroke-linecap='round' stroke-linejoin='round'><path d='M12 5v15M12 5C9 3 5 3 2 4v15c3-1 7-1 10 1 3-2 7-2 10-1V4c-3-1-7-1-10 1Z'/></svg></a>
          <a class='icon-link' href='https://github.com/bmehder/cheekycms' aria-label='CheekyCMS on GitHub' title='CheekyCMS on GitHub'><svg aria-hidden='true' focusable='false' width='22' height='22' viewBox='0 0 24 24' fill='currentColor'><path d='M12 .75a11.25 11.25 0 0 0-3.558 21.922c.563.104.768-.244.768-.542 0-.267-.01-.975-.015-1.914-3.13.68-3.791-1.508-3.791-1.508-.512-1.3-1.25-1.646-1.25-1.646-1.022-.698.077-.684.077-.684 1.13.08 1.725 1.16 1.725 1.16 1.005 1.722 2.637 1.225 3.28.937.102-.728.393-1.225.714-1.507-2.498-.284-5.124-1.25-5.124-5.563 0-1.229.44-2.232 1.16-3.02-.116-.284-.503-1.429.11-2.978 0 0 .945-.303 3.094 1.154a10.784 10.784 0 0 1 5.626 0c2.147-1.457 3.09-1.154 3.09-1.154.615 1.55.228 2.694.112 2.978.722.788 1.158 1.791 1.158 3.02 0 4.324-2.63 5.276-5.136 5.555.404.35.764 1.042.764 2.1 0 1.516-.014 2.739-.014 3.11 0 .3.203.65.774.54A11.252 11.252 0 0 0 12 .75Z'/></svg></a>
        </div>
      </nav>

      " <> body_html <> "

      <footer class='wrap'><span>CheekyCMS · Built with Gleam on the BEAM</span><span>MIT licensed · No dashboard lurking backstage</span></footer>
    </body>
  </html>
  "
}

/// Return the standalone mark used by browsers for the site icon.
pub fn favicon_svg() -> String {
  "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'>
    <rect width='64' height='64' rx='14' fill='#11100f'/>
    <g transform='rotate(-4 32 32)'>
      <rect x='10' y='10' width='44' height='44' rx='12' fill='#ff6b4a'/>
      <path d='M42 23.5c-2.5-2.5-5.6-3.8-9.2-3.8-7.3 0-12.8 5.2-12.8 12.4s5.5 12.4 12.8 12.4c3.8 0 7-1.3 9.5-4l-4.1-4.2c-1.4 1.4-3.1 2.1-5.1 2.1-3.7 0-6.3-2.6-6.3-6.3s2.6-6.3 6.3-6.3c1.9 0 3.6.7 5 2l3.9-4.3Z' fill='#11100f'/>
    </g>
  </svg>"
}

// Escape metadata before inserting it into HTML attributes and the title.
fn escape(value: String) -> String {
  value
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&#39;")
}
