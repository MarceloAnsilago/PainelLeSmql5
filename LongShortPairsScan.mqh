#property strict
#ifndef __LONGSHORTPAIRSSCAN_MQH__
#define __LONGSHORTPAIRSSCAN_MQH__

#include "LongShortMetrics.mqh"

struct PairMetrics
{
   double corr;
   double score;
   double beta;
   double z;
   double half;
   double adf;
   bool has_beta;
   bool has_z;
   bool has_half;
   bool has_adf;
   bool pass;
};

struct PairMainRow
{
   string sym_a;
   string sym_b;
   PairMetrics metrics;
   bool corr_valid;
   string status;
   int window;
};

struct PairDetailRow
{
   int window;
   PairMetrics metrics;
   bool corr_valid;
   string status;
};

struct PairScanConfig
{
   int base_window;
   int windows[];
   int windows_total;
   double corr_min;
   double z_min;
   double adf_min;
   double half_max;
   int beta_window;
};

PairMainRow g_pairs_results[];
PairDetailRow g_pairs_detail_rows[];
int g_pairs_selected_index = -1;
int g_pairs_detail_base_window = 0;

bool g_pairs_scan_running = false;
int g_pairs_scan_i = 0;
int g_pairs_scan_j = 0;
int g_pairs_scan_processed = 0;
int g_pairs_scan_total = 0;
int g_pairs_scan_batch = 60;
string g_pairs_scan_symbols[];
PairScanConfig g_pairs_scan_cfg;
string g_pairs_status_base = "";
string g_pairs_detail_pair = "";

double ParseDoubleText(const string text, const double fallback)
{
   string t = text;
   StringTrimLeft(t);
   StringTrimRight(t);
   if(t == "")
      return(fallback);
   StringReplace(t, ",", ".");
   return(StringToDouble(t));
}

int ParseIntText(const string text, const int fallback)
{
   string t = text;
   StringTrimLeft(t);
   StringTrimRight(t);
   if(t == "")
      return(fallback);
   return((int)StringToInteger(t));
}

int ParseWindowsList(const string text, int &out[])
{
   ArrayResize(out, 0);
   string t = text;
   StringTrimLeft(t);
   StringTrimRight(t);
   if(t == "")
      return(0);
   string parts[];
   const int total = StringSplit(t, ',', parts);
   for(int i = 0; i < total; i++)
     {
      string item = parts[i];
      StringTrimLeft(item);
      StringTrimRight(item);
      if(item == "")
         continue;
      const int val = (int)StringToInteger(item);
      if(val > 0)
        {
         const int idx = ArraySize(out);
         ArrayResize(out, idx + 1);
         out[idx] = val;
        }
     }
   return(ArraySize(out));
}

int BuildSelectedSymbols()
{
   int count = 0;
   ArrayResize(g_selected_symbols, 0);
   for(int i = 0; i < g_action_total; i++)
     {
      if(g_action_checks[i].Checked())
        {
         ArrayResize(g_selected_symbols, count + 1);
         g_selected_symbols[count] = g_action_symbols[i];
         count++;
        }
     }
   return(count);
}

bool TimesAligned(const datetime &a[], const datetime &b[], const int count)
{
   for(int i = 0; i < count; i++)
     {
      if(a[i] != b[i])
         return(false);
     }
   return(true);
}

string FormatMetric(const double value, const bool valid, const int digits)
{
   if(!valid)
      return("N/A");
   return(DoubleToString(value, digits));
}

void ResetPairMetrics(PairMetrics &m)
{
   m.corr = 0.0;
   m.score = 0.0;
   m.beta = 0.0;
   m.z = 0.0;
   m.half = 0.0;
   m.adf = 0.0;
   m.has_beta = false;
   m.has_z = false;
   m.has_half = false;
   m.has_adf = false;
   m.pass = false;
}

void CopyScanConfig(const PairScanConfig &src, PairScanConfig &dst)
{
   dst.base_window = src.base_window;
   dst.corr_min = src.corr_min;
   dst.z_min = src.z_min;
   dst.adf_min = src.adf_min;
   dst.half_max = src.half_max;
   dst.beta_window = src.beta_window;
   dst.windows_total = src.windows_total;
   ArrayResize(dst.windows, dst.windows_total);
   for(int i = 0; i < dst.windows_total; i++)
      dst.windows[i] = src.windows[i];
}

bool ComputePairMetrics(const string sym_a, const string sym_b, const int window, const double corr_min, PairMetrics &out)
{
   ResetPairMetrics(out);
   if(window < 2)
      return(false);

   const int bars_needed = window + 1;
   double closes_a[];
   double closes_b[];
   datetime times_a[];
   datetime times_b[];
   const int got_a = CopyClose(sym_a, PERIOD_D1, 0, bars_needed, closes_a);
   const int got_b = CopyClose(sym_b, PERIOD_D1, 0, bars_needed, closes_b);
   if(got_a < bars_needed || got_b < bars_needed)
      return(false);
   const int got_ta = CopyTime(sym_a, PERIOD_D1, 0, bars_needed, times_a);
   const int got_tb = CopyTime(sym_b, PERIOD_D1, 0, bars_needed, times_b);
   if(got_ta < bars_needed || got_tb < bars_needed)
      return(false);
   if(!TimesAligned(times_a, times_b, bars_needed))
      return(false);

   double corr = 0.0;
   if(!CorrPearsonReturnsFromPrices(closes_a, closes_b, bars_needed, window, corr))
      return(false);
   out.corr = corr;
   out.score = ScoreCorr(corr, corr_min);

   double beta = 0.0;
   if(CalcBetaOLS(closes_a, closes_b, bars_needed, window, beta))
     {
      out.beta = beta;
      out.has_beta = true;
     }

   double spread[];
   ArrayResize(spread, window);
   for(int i = 0; i < window; i++)
      spread[i] = closes_a[i] - closes_b[i];

   double zscore = 0.0;
   if(CalcZScore(spread, window, window, zscore))
     {
      out.z = zscore;
      out.has_z = true;
     }

   double half = 0.0;
   if(CalcHalfLife(spread, window, half))
     {
      out.half = half;
      out.has_half = true;
     }

   double adf = 0.0;
   if(CalcADF(spread, window, adf))
     {
      out.adf = adf;
      out.has_adf = true;
     }

   return(true);
}

bool PassAdfThreshold(const double adf_value, const double adf_min)
{
   if(adf_min <= 0.0)
      return(true);
   double threshold = adf_min;
   if(threshold > 1.0)
      threshold = threshold / 100.0;
   if(adf_value >= 0.0 && adf_value <= 1.0)
      return(adf_value <= (1.0 - threshold));
   return(adf_value >= threshold);
}

bool PairPassesFilters(const PairMetrics &m, const PairScanConfig &cfg)
{
   if(m.corr < cfg.corr_min)
      return(false);
   if(cfg.z_min > 0.0 && m.has_z && MathAbs(m.z) < cfg.z_min)
      return(false);
   if(cfg.half_max > 0.0 && m.has_half && m.half > cfg.half_max)
      return(false);
   if(cfg.adf_min > 0.0 && m.has_adf && !PassAdfThreshold(m.adf, cfg.adf_min))
      return(false);
   return(true);
}

void AppendPairResult(const PairMainRow &row)
{
   const int idx = ArraySize(g_pairs_results);
   ArrayResize(g_pairs_results, idx + 1);
   g_pairs_results[idx] = row;
}

void SortPairsByScore()
{
   const int total = ArraySize(g_pairs_results);
   for(int i = 0; i < total - 1; i++)
     {
      for(int j = i + 1; j < total; j++)
        {
         if(g_pairs_results[j].metrics.score > g_pairs_results[i].metrics.score)
           {
            PairMainRow tmp = g_pairs_results[i];
            g_pairs_results[i] = g_pairs_results[j];
            g_pairs_results[j] = tmp;
           }
        }
     }
}

void UpdatePairsStatusLabel()
{
   string text = g_pairs_status_base;
   if(g_pairs_detail_pair != "")
     {
      if(text != "")
         text += " | ";
      text += "Detalhe do par: " + g_pairs_detail_pair;
     }
   g_pairs_status.Text(text);
}

void ClearDetailSelection()
{
   g_pairs_detail_pair = "";
   g_pairs_selected_index = -1;
   g_pairs_detail_base_window = 0;
}

void FillMainGrid()
{
   const int total = ArraySize(g_pairs_results);
   if(g_pairs_visible_rows < 1)
      g_pairs_visible_rows = 1;
   int max_scroll = total - g_pairs_visible_rows;
   if(max_scroll < 0)
      max_scroll = 0;
   g_pairs_scroll.MinPos(0);
   g_pairs_scroll.MaxPos(max_scroll);
   g_pairs_scroll_pos = g_pairs_scroll.CurrPos();
   if(g_pairs_scroll_pos > max_scroll)
      g_pairs_scroll_pos = max_scroll;
   if(g_pairs_scroll_pos < 0)
      g_pairs_scroll_pos = 0;
   g_pairs_scroll.CurrPos(g_pairs_scroll_pos);

   if(total <= 0)
     {
      g_pairs_empty.Text("Nenhum par aprovado na janela base");
      g_pairs_empty.Visible(true);
      for(int i = 0; i < ArraySize(g_pairs_cells); i++)
         g_pairs_cells[i].Visible(false);
      return;
     }

   g_pairs_empty.Visible(false);
   for(int row = 0; row < g_pairs_visible_rows; row++)
     {
      const int data_index = g_pairs_scroll_pos + row;
      const color row_bg = (data_index % 2 == 0) ? g_pairs_row_bg_a : g_pairs_row_bg_b;
      for(int col = 0; col < PAIRS_COLS; col++)
        {
         const int idx = row * PAIRS_COLS + col;
         if(data_index >= total)
           {
            g_pairs_cells[idx].Visible(false);
            continue;
           }
         const PairMainRow r = g_pairs_results[data_index];
         string text = "";
         if(col == 0)
            text = r.sym_a + "/" + r.sym_b;
         else if(col == 1)
            text = FormatMetric(r.metrics.corr, r.corr_valid, 3);
         else if(col == 2)
            text = FormatMetric(r.metrics.score, r.corr_valid, 2);
         else if(col == 3)
            text = FormatMetric(r.metrics.beta, r.metrics.has_beta, 3);
         else if(col == 4)
            text = FormatMetric(r.metrics.z, r.metrics.has_z, 2);
         else if(col == 5)
            text = FormatMetric(r.metrics.half, r.metrics.has_half, 2);
         else if(col == 6)
            text = FormatMetric(r.metrics.adf, r.metrics.has_adf, 2);
         else if(col == 7)
            text = r.status;
         else if(col == 8)
            text = IntegerToString(r.window);

         g_pairs_cells[idx].Text(text);
         g_pairs_cells[idx].ColorBackground(row_bg);
         g_pairs_cells[idx].Visible(true);
        }
     }
}

void UpdatePairsDetailGrid()
{
   const int total = ArraySize(g_pairs_detail_rows);
   if(g_pairs_detail_visible_rows < 1)
      g_pairs_detail_visible_rows = 1;
   int max_scroll = total - g_pairs_detail_visible_rows;
   if(max_scroll < 0)
      max_scroll = 0;
   g_pairs_detail_scroll.MinPos(0);
   g_pairs_detail_scroll.MaxPos(max_scroll);
   g_pairs_detail_scroll_pos = g_pairs_detail_scroll.CurrPos();
   if(g_pairs_detail_scroll_pos > max_scroll)
      g_pairs_detail_scroll_pos = max_scroll;
   if(g_pairs_detail_scroll_pos < 0)
      g_pairs_detail_scroll_pos = 0;
   g_pairs_detail_scroll.CurrPos(g_pairs_detail_scroll_pos);

   if(total <= 0)
     {
      const string empty_text = (g_pairs_detail_pair == "" ? "Selecione um par no grid principal." : "Sem dados para o par selecionado.");
      g_pairs_detail_empty.Text(empty_text);
      g_pairs_detail_empty.Visible(true);
      for(int i = 0; i < ArraySize(g_pairs_detail_cells); i++)
         g_pairs_detail_cells[i].Visible(false);
      return;
     }

   g_pairs_detail_empty.Visible(false);
   for(int row = 0; row < g_pairs_detail_visible_rows; row++)
     {
      const int data_index = g_pairs_detail_scroll_pos + row;
      const color row_bg = (data_index % 2 == 0) ? g_pairs_row_bg_a : g_pairs_row_bg_b;
      for(int col = 0; col < PAIRS_DETAIL_COLS; col++)
        {
         const int idx = row * PAIRS_DETAIL_COLS + col;
         if(data_index >= total)
           {
            g_pairs_detail_cells[idx].Visible(false);
            continue;
           }
         const PairDetailRow r = g_pairs_detail_rows[data_index];
         string text = "";
         if(col == 0)
           {
            text = IntegerToString(r.window);
            if(r.window == g_pairs_detail_base_window)
               text += "*";
           }
         else if(col == 1)
            text = FormatMetric(r.metrics.corr, r.corr_valid, 3);
         else if(col == 2)
            text = FormatMetric(r.metrics.score, r.corr_valid, 2);
         else if(col == 3)
            text = FormatMetric(r.metrics.beta, r.metrics.has_beta, 3);
         else if(col == 4)
            text = FormatMetric(r.metrics.z, r.metrics.has_z, 2);
         else if(col == 5)
            text = FormatMetric(r.metrics.half, r.metrics.has_half, 2);
         else if(col == 6)
            text = FormatMetric(r.metrics.adf, r.metrics.has_adf, 2);
         else if(col == 7)
            text = r.status;

         g_pairs_detail_cells[idx].Text(text);
         g_pairs_detail_cells[idx].ColorBackground(row_bg);
         g_pairs_detail_cells[idx].Visible(true);
        }
     }
}

void AddDetailRow(const PairDetailRow &row)
{
   const int idx = ArraySize(g_pairs_detail_rows);
   ArrayResize(g_pairs_detail_rows, idx + 1);
   g_pairs_detail_rows[idx] = row;
}

void SortDetailByWindow()
{
   const int total = ArraySize(g_pairs_detail_rows);
   for(int i = 0; i < total - 1; i++)
     {
      for(int j = i + 1; j < total; j++)
        {
         if(g_pairs_detail_rows[j].window < g_pairs_detail_rows[i].window)
           {
            PairDetailRow tmp = g_pairs_detail_rows[i];
            g_pairs_detail_rows[i] = g_pairs_detail_rows[j];
            g_pairs_detail_rows[j] = tmp;
           }
        }
     }
}

bool WindowListContains(const int &list[], const int value)
{
   for(int i = 0; i < ArraySize(list); i++)
     {
      if(list[i] == value)
         return(true);
     }
   return(false);
}

bool FillDetailGridForSelectedPair(const int data_index, const PairScanConfig &cfg)
{
   if(data_index < 0 || data_index >= ArraySize(g_pairs_results))
      return(false);

   const PairMainRow base = g_pairs_results[data_index];
   g_pairs_selected_index = data_index;
   g_pairs_detail_pair = base.sym_a + "/" + base.sym_b;
   g_pairs_detail_base_window = cfg.base_window;
   g_pairs_detail_scroll_pos = 0;
   g_pairs_detail_scroll.CurrPos(0);

   int windows[];
   if(cfg.windows_total > 0)
     {
      ArrayResize(windows, cfg.windows_total);
      for(int i = 0; i < cfg.windows_total; i++)
         windows[i] = cfg.windows[i];
     }
   else
     {
      ArrayResize(windows, 1);
      windows[0] = cfg.base_window;
     }

   if(!WindowListContains(windows, cfg.base_window))
     {
      const int idx = ArraySize(windows);
      ArrayResize(windows, idx + 1);
      windows[idx] = cfg.base_window;
     }

   ArrayResize(g_pairs_detail_rows, 0);
   for(int i = 0; i < ArraySize(windows); i++)
     {
      const int window = windows[i];
      PairMetrics m;
      const bool corr_ok = ComputePairMetrics(base.sym_a, base.sym_b, window, cfg.corr_min, m);
      PairDetailRow row;
      row.window = window;
      row.metrics = m;
      row.corr_valid = corr_ok;
      if(corr_ok)
        {
         row.metrics.pass = PairPassesFilters(m, cfg);
         row.status = row.metrics.pass ? "PASS" : "FAIL";
        }
      else
        {
         row.status = "N/A";
        }
      AddDetailRow(row);
     }

   SortDetailByWindow();
   UpdatePairsStatusLabel();
   UpdatePairsDetailGrid();
   return(true);
}

bool ScanPairsBaseWindow(const string &symbols[], const int symbols_total, const PairScanConfig &cfg, const int batch_size)
{
   ArrayResize(g_pairs_results, 0);
   ArrayResize(g_pairs_detail_rows, 0);
   ClearDetailSelection();
   CopyScanConfig(cfg, g_pairs_scan_cfg);
   g_pairs_scan_processed = 0;
   g_pairs_scan_total = 0;
   g_pairs_scan_i = 0;
   g_pairs_scan_j = 1;
   g_pairs_scan_batch = batch_size;
   g_pairs_scan_running = false;
   g_pairs_scroll_pos = 0;
   g_pairs_scroll.CurrPos(0);
   g_pairs_detail_scroll_pos = 0;
   g_pairs_detail_scroll.CurrPos(0);

   if(symbols_total < 2)
     {
      g_pairs_status_base = "Selecione pelo menos 2 ativos na aba Cotacoes.";
      UpdatePairsStatusLabel();
      FillMainGrid();
      UpdatePairsDetailGrid();
      return(false);
     }

   ArrayResize(g_pairs_scan_symbols, symbols_total);
   for(int i = 0; i < symbols_total; i++)
      g_pairs_scan_symbols[i] = symbols[i];
   g_pairs_scan_total = (symbols_total * (symbols_total - 1)) / 2;
   g_pairs_scan_running = true;
   g_pairs_status_base = "Scan 0/" + IntegerToString(g_pairs_scan_total);
   UpdatePairsStatusLabel();
   FillMainGrid();
   UpdatePairsDetailGrid();
   return(true);
}

bool ProcessPairsScanBatch()
{
   if(!g_pairs_scan_running)
      return(true);

   const int symbols_total = ArraySize(g_pairs_scan_symbols);
   int processed_now = 0;
   bool done = false;
   while(processed_now < g_pairs_scan_batch)
     {
      if(g_pairs_scan_i >= symbols_total - 1)
        {
         done = true;
         break;
        }

      const string sym_a = g_pairs_scan_symbols[g_pairs_scan_i];
      const string sym_b = g_pairs_scan_symbols[g_pairs_scan_j];
      PairMetrics m;
      const bool corr_ok = ComputePairMetrics(sym_a, sym_b, g_pairs_scan_cfg.base_window, g_pairs_scan_cfg.corr_min, m);
      if(corr_ok)
        {
         PairMainRow row;
         row.sym_a = sym_a;
         row.sym_b = sym_b;
         row.metrics = m;
         row.corr_valid = true;
         row.metrics.pass = PairPassesFilters(m, g_pairs_scan_cfg);
         row.status = row.metrics.pass ? "PASS" : "FAIL";
         row.window = g_pairs_scan_cfg.base_window;
         if(row.metrics.pass)
            AppendPairResult(row);
        }

      g_pairs_scan_processed++;
      processed_now++;

      g_pairs_scan_j++;
      if(g_pairs_scan_j >= symbols_total)
        {
         g_pairs_scan_i++;
         g_pairs_scan_j = g_pairs_scan_i + 1;
        }
     }

   const int approved = ArraySize(g_pairs_results);
   g_pairs_status_base = "Scan " + IntegerToString(g_pairs_scan_processed) + "/" + IntegerToString(g_pairs_scan_total) +
      " | aprovados: " + IntegerToString(approved);
   UpdatePairsStatusLabel();
   ChartRedraw(0);

   if(done)
     {
      g_pairs_scan_running = false;
      SortPairsByScore();
      g_pairs_status_base = "Scan concluido: " + IntegerToString(approved) + " pares aprovados na janela base " +
         IntegerToString(g_pairs_scan_cfg.base_window);
      UpdatePairsStatusLabel();
      FillMainGrid();
      ChartRedraw(0);
      return(true);
     }

   return(false);
}

#endif // __LONGSHORTPAIRSSCAN_MQH__
