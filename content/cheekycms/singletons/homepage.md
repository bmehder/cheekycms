---
title: CheekyCMS — Markdown in, JSON out
description: A cheeky little Markdown content API, written in Gleam.
published: 2026-10-02
purpose: marketing-homepage
---

<main>
  <header class='hero'>
    <div class='wrap'>
      <div class='eyebrow'>Markdown in · JSON out · Gleam throughout</div>
      <h1>A cheeky little <em>content API.</em></h1>
      <p class='lede'>Put Markdown and assets in a repository. CheekyCMS serves them as structured metadata and rendered HTML—with room for several projects if that’s how you like to organise things.</p>
      <div class='actions'><a class='button primary' href='/api'>Explore the live API →</a><a class='button' href='/reference/'>Browse the Gleam reference</a><a class='button' href='https://github.com/bmehder/cheekycms'>Read the code</a></div>
    </div>
  </header>

  <section>
    <div class='wrap'>
      <h2>Just files. Then an API.</h2>
      <p class='section-intro'>YAML frontmatter becomes metadata. Markdown becomes HTML. The response is ordinary JSON that any frontend can use.</p>
      <div class='demo'>
        <div class='code'><span class='label'>content/studio/collections/projects/orbit.md</span><pre>---&#10;<span class='key'>title:</span> <span class='value'>Orbit</span>&#10;<span class='key'>description:</span> <span class='value'>Product strategy and interface work…</span>&#10;<span class='key'>published:</span> <span class='value'>2026-10-02</span>&#10;<span class='key'>featured:</span> true&#10;---&#10;&#10;&#35; A calmer way to travel&#10;&#10;Journey planning without the noise.</pre></div>
        <div class='code'><span class='label'>GET /api/studio/collections/projects/orbit</span><pre>{&#10;  <span class='key'>&quot;metadata&quot;</span>: {&#10;    <span class='key'>&quot;title&quot;</span>: <span class='value'>&quot;Orbit&quot;</span>,&#10;    <span class='key'>&quot;description&quot;</span>: <span class='value'>&quot;Product strategy and interface work…&quot;</span>,&#10;    <span class='key'>&quot;published&quot;</span>: <span class='value'>&quot;2026-10-02&quot;</span>,&#10;    <span class='key'>&quot;featured&quot;</span>: true&#10;  },&#10;  <span class='key'>&quot;html&quot;</span>: <span class='value'>&quot;&lt;h1&gt;A calmer way to travel&lt;/h1&gt;…&quot;</span>&#10;}</pre></div>
      </div>
      <div class='actions'><a class='button' href='https://svelte.dev/playground/c592c1110b2a469eb915157f31117019?version=5.57.2' target='_blank' rel='noreferrer'>Try the API response tester — JSON + timing →</a></div>
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
        <div class='actions'><a class='button primary' href='/api'>Browse sample data</a><a class='button' href='https://github.com/bmehder/cheekycms/blob/main/content/cheekycms/collections/guides/inside-cheekycms.md'>Take the code tour</a></div>
      </div>
    </div>
  </section>
</main>
