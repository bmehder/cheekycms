/// Render the small public introduction served at the root URL.
pub fn html() -> String {
  "
  <!doctype html>
  <html lang='en'>
    <head>
      <meta charset='utf-8'>
      <meta name='viewport' content='width=device-width, initial-scale=1'>
      <meta name='description' content='A cheeky little Markdown content API, written in Gleam.'>
      <meta name='theme-color' content='#11100f'>
      <meta property='og:title' content='CheekyCMS — Markdown in, JSON out'>
      <meta property='og:description' content='A cheeky little Markdown content API, written in Gleam.'>
      <meta property='og:type' content='website'>
      <meta property='og:url' content='https://cheekycms.fly.dev/'>
      <meta name='twitter:card' content='summary'>
      <link rel='canonical' href='https://cheekycms.fly.dev/'>
      <title>CheekyCMS — Markdown in, JSON out</title>
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
        <div class='navlinks'><a href='#about'>What it is</a><a href='/api'>Explore the API</a><a href='https://github.com/bmehder/cheekycms'>GitHub</a></div>
      </nav>

      <main>
        <header class='hero'>
          <div class='wrap'>
            <div class='eyebrow'>Markdown in · JSON out · Gleam throughout</div>
            <h1>A cheeky little <em>content API.</em></h1>
            <p class='lede'>Put Markdown and assets in a repository. CheekyCMS serves them as structured metadata and rendered HTML—with room for several projects if that’s how you like to organise things.</p>
            <div class='actions'><a class='button primary' href='/api'>Explore the live API →</a><a class='button' href='https://github.com/bmehder/cheekycms'>Read the code</a></div>
          </div>
        </header>

        <section>
          <div class='wrap'>
            <h2>Just files. Then an API.</h2>
            <p class='section-intro'>YAML frontmatter becomes metadata. Markdown becomes HTML. The response is ordinary JSON that any frontend can use.</p>
            <div class='demo'>
              <div class='code'><span class='label'>content/studio/collections/projects/orbit.md</span><pre>---
<span class='key'>title:</span> <span class='value'>Orbit</span>
<span class='key'>featured:</span> true
<span class='key'>tags:</span>
  - transport
  - research
---

# A calmer way to travel

Journey planning without the noise.</pre></div>
              <div class='code'><span class='label'>GET /api/studio/collections/projects/orbit</span><pre>{
  <span class='key'>&quot;metadata&quot;</span>: {
    <span class='key'>&quot;title&quot;</span>: <span class='value'>&quot;Orbit&quot;</span>,
    <span class='key'>&quot;featured&quot;</span>: true,
    <span class='key'>&quot;tags&quot;</span>: [<span class='value'>&quot;transport&quot;</span>, <span class='value'>&quot;research&quot;</span>]
  },
  <span class='key'>&quot;html&quot;</span>: <span class='value'>&quot;&lt;h1&gt;A calmer way to travel&lt;/h1&gt;…&quot;</span>
}</pre></div>
            </div>
          </div>
        </section>

        <section id='about'>
          <div class='wrap'>
            <h2>Small on purpose.</h2>
            <p class='section-intro'>CheekyCMS is content delivery more than content management. Git is the editor, history, and publishing workflow. The service does the useful bit in between.</p>
            <div class='cards'>
              <article class='card'><strong>Markdown-first</strong><p>Write portable content with arbitrary nested YAML metadata and raw HTML when you need it.</p></article>
              <article class='card'><strong>Many projects, one place</strong><p>Use one installation per project—or make a tiny data monorepo. Is that always wise? Maybe not. You can do you.</p></article>
              <article class='card'><strong>Fast, boring delivery</strong><p>Content is rendered at startup and served from memory on the BEAM. Assets, responsive images, CORS, and range requests are included.</p></article>
            </div>
          </div>
        </section>

        <section>
          <div class='wrap honest'>
            <div>
              <h2>What it is.</h2>
              <ul class='list yes'><li>A read-only JSON API</li><li>Collections and singletons</li><li>Repository-backed files and media</li><li>Automatic deployment from GitHub</li><li>A small Gleam service you can actually read</li></ul>
            </div>
            <div class='aside'>
              <big>Not a visual editor. Not a workflow platform. Not the greatest new thing in content management.</big>
              <p>Full CMSs offer dashboards, permissions, drafts, and editorial workflows. CheekyCMS does not. It turns a straightforward folder of Markdown into a reusable API, and tries to do that job well.</p>
              <div class='actions'><a class='button primary' href='/api'>Browse sample data</a><a class='button' href='https://github.com/bmehder/cheekycms#readme'>Documentation</a></div>
            </div>
          </div>
        </section>
      </main>

      <footer class='wrap'><span>CheekyCMS · Built with Gleam on the BEAM</span><span>MIT licensed · No dashboard lurking backstage</span></footer>
    </body>
  </html>
  "
}
