// Gera o PDF de um documento HTML do projeto, no padrão A4.
//
// Uso:  node _identidade/gerar-pdf.js caminho/do/documento.html
// Saída: mesmo caminho, com extensão .pdf
//
// Requer Playwright (npm i -g playwright). Sem ele, abra o HTML no Chrome
// e use Imprimir > Salvar como PDF (margens: nenhuma; ative "gráficos de fundo").

const path = require("path");
const { chromium } = require("playwright");

(async () => {
  const entrada = process.argv[2];
  if (!entrada) {
    console.error("Informe o arquivo HTML. Ex.: node _identidade/gerar-pdf.js 03-propostas/servicos-gerais/proposta-servicos.html");
    process.exit(1);
  }
  const html = path.resolve(entrada);
  const pdf = html.replace(/\.html?$/i, ".pdf");

  const navegador = await chromium.launch();
  const pagina = await navegador.newPage();
  await pagina.goto("file://" + html, { waitUntil: "networkidle" });
  await pagina.evaluate(() => document.fonts.ready);

  await pagina.pdf({
    path: pdf,
    format: "A4",
    printBackground: true,
    preferCSSPageSize: true,
  });

  await navegador.close();
  console.log("PDF gerado:", path.relative(process.cwd(), pdf));
})();
