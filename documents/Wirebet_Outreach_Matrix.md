<style>
  /* WIREBET STRATEGIC DESIGN SYSTEM — v3.6 */
  /* Matrix variant: landscape, table-centric */
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500&family=Outfit:wght@300;400;500;600&display=swap');

  @page { size: A4 landscape; margin: 0; }
  html, body {
    background-color: #000000;
    color: rgba(212, 212, 216, 0.85); /* Zinc-300 / 0.85 */
    font-family: 'Inter', -apple-system, sans-serif;
    line-height: 1.95;
    font-size: 10.5px;
    font-weight: 350;
    margin: 0; padding: 0;
    -webkit-font-smoothing: antialiased;
  }
  .doc-container {
    max-width: 1380px;
    margin: 0 auto;
    padding: 4em 7em;
    min-height: 100vh;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
  }
  .header-block {
    text-align: center;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08); /* Smoked border */
    padding-bottom: 3.5em;
    margin-bottom: 4.5em;
    background: radial-gradient(circle at 50% 40%, rgba(255, 255, 255, 0.02) 0%, transparent 70%);
  }
  h1 { 
    font-family: 'Outfit', sans-serif;
    letter-spacing: 0.6em; 
    font-size: 2.6em; 
    margin: 0 0 0.6em 0; 
    color: #ffffff; 
    font-weight: 400; 
    text-transform: uppercase; 
    background: linear-gradient(178deg, #ffffff 0%, rgba(255, 255, 255, 0.8) 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }
  .subtitle { 
    font-family: 'Inter', sans-serif;
    letter-spacing: 0.4em; 
    font-size: 0.8em; 
    text-transform: uppercase; 
    color: rgba(161, 161, 170, 0.75); 
    margin-bottom: 2em; 
  }
  .bottom-line { 
    font-size: 0.58em; 
    text-transform: uppercase; 
    letter-spacing: 0.52em; 
    color: rgba(113, 113, 122, 0.5); 
    font-weight: 500; 
  }

  .section-title {
    font-family: 'Outfit', sans-serif;
    text-transform: uppercase;
    font-size: 0.72em;
    font-weight: 500;
    color: #ffffff;
    letter-spacing: 0.35em;
    margin-bottom: 2.5em;
    border-left: 1px solid rgba(255, 255, 255, 0.12);
    padding-left: 1.8em;
  }
  .intro-text { 
    color: rgba(161, 161, 170, 0.7); 
    padding-left: 1.8em; 
    margin-bottom: 5em; 
    max-width: 650px; 
    letter-spacing: 0.03em; 
  }

  table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 6em;
    border-top: 1px solid rgba(255, 255, 255, 0.06);
  }
  th {
    font-family: 'Outfit', sans-serif;
    text-align: left;
    text-transform: uppercase;
    letter-spacing: 0.35em;
    font-size: 0.66em;
    font-weight: 500;
    color: rgba(113, 113, 122, 0.6);
    padding: 2.2em 1.5em 1.8em 1.5em;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  }
  td {
    padding: 2.2em 1.5em;
    border-bottom: 1px solid rgba(255, 255, 255, 0.035);
    color: rgba(161, 161, 170, 0.85);
    vertical-align: top;
    line-height: 1.85;
  }

  .col-priority { color: rgba(113, 113, 122, 0.45); font-weight: 500; width: 4%; text-align: center; font-size: 0.8em; }
  .col-type { width: 14%; color: rgba(161, 161, 170, 0.65); font-size: 0.9em; }
  .col-target { width: 12%; color: #ffffff; font-weight: 400; letter-spacing: 0.06em; font-family: 'Outfit', sans-serif; }
  .col-pitch { width: 26%; }
  .col-role { width: 14%; color: rgba(161, 161, 170, 0.65); font-size: 0.9em; }
  .col-status { width: 12%; }
  .col-step { width: 18%; color: rgba(161, 161, 170, 0.75); }

  .status-badge {
    display: inline-block;
    border: 1px solid rgba(255, 255, 255, 0.05);
    padding: 0.45em 1em;
    font-size: 0.68em;
    text-transform: uppercase;
    letter-spacing: 0.22em;
    color: rgba(161, 161, 170, 0.6);
    border-radius: 0;
  }

  .content-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8.5em;
    padding-top: 4em;
    border-top: 1px solid rgba(255, 255, 255, 0.05);
    margin-top: auto;
  }

  ul { padding-left: 0; margin-top: 1.2em; margin-bottom: 0; list-style-type: none; }
  li { margin-bottom: 1.1em; line-height: 1.9; position: relative; padding-left: 1.8em; color: rgba(161, 161, 170, 0.8); }
  li::before { content: ""; position: absolute; left: 0; top: 0.9em; width: 0.6em; height: 1px; background-color: rgba(255, 255, 255, 0.12); }
</style>

<div class="doc-container">

  <!-- HEADER -->
  <div class="header-block">
    <h1>WIREBET</h1>
    <div class="subtitle">Buyer Outreach Matrix</div>
    <div class="subtitle" style="font-size: 0.62em; margin-top: -1.5em; opacity: 0.7;">Strategic Target & Execution Map</div>
    <div class="bottom-line">Private investment, partnership, and acquisitions discussions only.</div>
  </div>

  <!-- SECTION 1 -->
  <div class="section-title">Section 1 — Intro Line</div>
  <div class="intro-text">
    This matrix prioritizes high-fit buyer categories and named targets aligned with the Wirebet prediction-markets thesis.
  </div>

  <!-- SECTION 2 -->
  <div class="section-title">Section 2 — Matrix Table</div>
  <table>
    <thead>
      <tr>
        <th style="text-align: center;">Priority</th>
        <th>Target Type</th>
        <th>Target</th>
        <th>Pitch Angle</th>
        <th>Best Contact Role</th>
        <th>Status</th>
        <th>Next Step</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="col-priority">01</td>
        <td class="col-type">Prediction market platform</td>
        <td class="col-target">Polymarket</td>
        <td class="col-pitch">Premium adjacent brand for fast crypto-native event markets</td>
        <td class="col-role">Founder / Biz Dev / Strategy</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Identify direct contact and send teaser</td>
      </tr>
      <tr>
        <td class="col-priority">02</td>
        <td class="col-type">Regulated event-market platform</td>
        <td class="col-target">Kalshi</td>
        <td class="col-pitch">Consumer-facing or future expansion brand for event-market products</td>
        <td class="col-role">Founder / Strategy / Corp Dev</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Identify direct contact and send teaser</td>
      </tr>
      <tr>
        <td class="col-priority">03</td>
        <td class="col-type">Forecasting / market-intelligence platform</td>
        <td class="col-target">Metaculus</td>
        <td class="col-pitch">Commercial-facing brand extension into market-backed participation products</td>
        <td class="col-role">Founder / Partnerships</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Identify strategic fit and send tailored note</td>
      </tr>
      <tr>
        <td class="col-priority">04</td>
        <td class="col-type">Prediction market / social market platform</td>
        <td class="col-target">Manifold</td>
        <td class="col-pitch">Premium market-facing brand layer for expansion or repositioning</td>
        <td class="col-role">Founder / Partnerships</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Send teaser with prediction-market framing</td>
      </tr>
      <tr>
        <td class="col-priority">05</td>
        <td class="col-type">Crypto sportsbook operator</td>
        <td class="col-target">Cloudbet</td>
        <td class="col-pitch">Future-facing brand to expand from sportsbook language into event markets</td>
        <td class="col-role">Founder / Growth / Brand</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Send teaser with premium event-market angle</td>
      </tr>
      <tr>
        <td class="col-priority">06</td>
        <td class="col-type">UAE / Dubai crypto founder</td>
        <td class="col-target">DMCC ecosystem target 1</td>
        <td class="col-pitch">Launch-ready premium brand for event markets or crypto-native forecasting products</td>
        <td class="col-role">Founder / CEO</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Build UAE target list</td>
      </tr>
      <tr>
        <td class="col-priority">07</td>
        <td class="col-type">UAE / Dubai crypto founder</td>
        <td class="col-target">DMCC ecosystem target 2</td>
        <td class="col-pitch">Strategic hold or launch brand for future-facing market products</td>
        <td class="col-role">Founder / CEO</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Build UAE target list</td>
      </tr>
      <tr>
        <td class="col-priority">08</td>
        <td class="col-type">UAE / Dubai Web3 operator</td>
        <td class="col-target">DMCC ecosystem target 3</td>
        <td class="col-pitch">Market-facing premium identity for a crypto-native consumer product</td>
        <td class="col-role">Founder / Strategy</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Build UAE target list</td>
      </tr>
      <tr>
        <td class="col-priority">09</td>
        <td class="col-type">Crypto wagering operator</td>
        <td class="col-target">Sportsbet.io / similar</td>
        <td class="col-pitch">Premium sub-brand for prediction / event-market expansion</td>
        <td class="col-role">Founder / Brand / Corp Dev</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Find best-fit contact</td>
      </tr>
      <tr>
        <td class="col-priority">10</td>
        <td class="col-type">Strategic acquirer</td>
        <td class="col-target">Web3 infrastructure brand</td>
        <td class="col-pitch">Strong consumer-facing naming layer for market or liquidity products</td>
        <td class="col-role">Founder / Strategy</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Curate shortlist</td>
      </tr>
      <tr>
        <td class="col-priority">11</td>
        <td class="col-type">Strategic acquirer</td>
        <td class="col-target">AI + forecasting product</td>
        <td class="col-pitch">Sharper public-facing brand for event-market or signal product launch</td>
        <td class="col-role">Founder / CEO</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Curate shortlist</td>
      </tr>
      <tr>
        <td class="col-priority">12</td>
        <td class="col-type">Strategic acquirer</td>
        <td class="col-target">Crypto exchange / market builder</td>
        <td class="col-pitch">Premium future brand for event-market vertical or expansion layer</td>
        <td class="col-role">Strategy / Corp Dev</td>
        <td class="col-status"><span class="status-badge">Not started</span></td>
        <td class="col-step">Curate shortlist</td>
      </tr>
    </tbody>
  </table>

  <!-- BOTTOM GRID -->
  <div class="content-grid">
    <div>
      <div class="section-title" style="margin-top: 0; border: none; padding-left: 0;">Section 3 — Outreach Rules</div>
      <ul>
        <li>Send the one-page teaser first when appropriate</li>
        <li>Send the full Strategic Brief only after early interest</li>
        <li>Use the prediction-markets thesis first, not gambling language</li>
        <li>Keep first outreach short and premium</li>
        <li>Track each response and do not over-message</li>
      </ul>
    </div>

    <div>
      <div class="section-title" style="margin-top: 0; border: none; padding-left: 0;">Section 4 — Status Labels</div>
      <ul style="column-count: 2; column-gap: 5.5em;">
        <li>Not started</li>
        <li>Contact identified</li>
        <li>First outreach sent</li>
        <li>Follow-up sent</li>
        <li>Warm interest</li>
        <li>In discussion</li>
        <li>Price discussion</li>
        <li>Closed / passed</li>
      </ul>
    </div>
  </div>

</div>
