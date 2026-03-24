<style>
  /* WIREBET STRATEGIC DESIGN SYSTEM — v3.6 */
  /* Teaser variant: single-page, dual-column grid */
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500&family=Outfit:wght@300;400;500;600&display=swap');

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
    max-width: 720px;
    margin: 0 auto;
    padding: 4em 5em;
    min-height: 100vh;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
  }
  .header-block {
    text-align: center;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08); /* Smoked border */
    padding-bottom: 3.5em;
    margin-bottom: 4em;
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
    margin-bottom: 2.5em; 
  }
  .circulation { 
    font-size: 0.58em; 
    text-transform: uppercase; 
    letter-spacing: 0.52em; 
    color: rgba(113, 113, 122, 0.5); 
    font-weight: 500; 
  }

  .content-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 6em;
    flex-grow: 1;
  }
  .col-left, .col-right {
    display: flex;
    flex-direction: column;
  }
  .section-group {
    display: flex;
    flex-direction: column;
    margin-bottom: 3.5em;
    border-top: 1px solid rgba(255, 255, 255, 0.06);
    padding-top: 1.8em;
  }
  .section-title {
    font-family: 'Outfit', sans-serif;
    text-transform: uppercase;
    font-size: 0.68em;
    font-weight: 500;
    color: #ffffff;
    letter-spacing: 0.35em;
    margin-bottom: 1.8em;
  }
  .section-text { color: rgba(161, 161, 170, 0.85); }

  ul { padding-left: 0; margin-top: 1.2em; margin-bottom: 0; list-style-type: none; }
  li { margin-bottom: 0.8em; line-height: 1.8; position: relative; padding-left: 1.8em; color: rgba(161, 161, 170, 0.8); }
  li::before { content: ""; position: absolute; left: 0; top: 0.8em; width: 0.6em; height: 1px; background-color: rgba(255, 255, 255, 0.12); }

  .footer {
    text-align: center;
    font-size: 0.58em;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.5em;
    color: rgba(113, 113, 122, 0.45);
    padding-top: 4em;
    border-top: 1px solid rgba(255, 255, 255, 0.05);
    margin-top: auto;
  }
</style>

<div class="doc-container">

  <!-- HEADER -->
  <div class="header-block">
    <h1>WIREBET</h1>
    <div class="subtitle">Premium Prediction-Markets Brand Asset</div>
    <div class="circulation">Private investment, partnership, and acquisitions discussions only.</div>
  </div>

  <!-- CONTENT -->
  <div class="content-grid">

    <!-- LEFT COLUMN -->
    <div class="col-left">

      <div class="section-group">
        <div class="section-title">Section 1 — Overview</div>
        <div class="section-text">
          Wirebet.com is a premium digital asset positioned for the next generation of prediction markets, crypto-native event products, and fast-settlement market participation.
          <br><br>
          Short, memorable, and commercially sharp, Wirebet is designed to sit at the intersection of:
          <ul>
            <li>event markets</li>
            <li>crypto rails</li>
            <li>market-backed conviction</li>
            <li>premium brand positioning</li>
          </ul>
        </div>
      </div>

      <div class="section-group">
        <div class="section-title">Section 2 — Core Thesis</div>
        <div class="section-text">
          Wirebet is a premium prediction-markets brand built for fast, crypto-native event markets.
        </div>
      </div>

      <div class="section-group">
        <div class="section-title">Section 3 — Why It Matters</div>
        <div class="section-text">
          <ul>
            <li>Strong .com asset with sharp recall</li>
            <li>Direct category fit for prediction and event markets</li>
            <li>Premium, future-facing commercial tone</li>
            <li>Flexible across launch, expansion, or acquisitions use</li>
            <li>Faster path to authority than building a new brand from zero</li>
          </ul>
        </div>
      </div>

    </div>

    <!-- RIGHT COLUMN -->
    <div class="col-right">

      <div class="section-group">
        <div class="section-title">Section 4 — Strategic Fit</div>
        <div class="section-text">
          Wirebet is well suited for:
          <ul>
            <li>prediction-market platforms</li>
            <li>crypto-native event products</li>
            <li>tokenized gaming and speculative participation products</li>
            <li>Web3 infrastructure brands needing a stronger market-facing identity</li>
            <li>strategic acquirers seeking category-aligned assets</li>
          </ul>
        </div>
      </div>

      <div class="section-group">
        <div class="section-title">Section 5 — High-Impact Value</div>
        <div class="section-text">
          <ul>
            <li>a premium digital brand asset</li>
            <li>a clean market-facing identity</li>
            <li>strong optionality across multiple deployment paths</li>
            <li>a ready-to-position asset for launch, expansion, or acquisitions strategy</li>
          </ul>
        </div>
      </div>

      <div class="section-group" style="border-bottom: 1px solid rgba(255, 255, 255, 0.06); padding-bottom: 2.5em;">
        <div class="section-title">Section 6 — Discussion Path</div>
        <div class="section-text">
          Available for selective discussions with qualified investors, founders, partners, operators, and acquirers.
        </div>
      </div>

    </div>

  </div>

  <!-- FOOTER -->
  <div class="footer">
    Strategic Access Available Upon Request
  </div>

</div>
