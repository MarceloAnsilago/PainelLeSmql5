#property strict
#property version   "1.001"

#include <Controls/Dialog.mqh>
#include <Controls/Panel.mqh>
#include <Controls/Button.mqh>
#include <Controls/Label.mqh>
#include <Controls/CheckBox.mqh>
#include <Controls/Edit.mqh>
#include <Controls/ListView.mqh>
#include <Controls/Scrolls.mqh>
#include "LongShortMetrics.mqh"

void UpdateCotacoesGrid();
void UpdatePairsGrid();
void UpdatePairsDetailGrid();

class CQuotesScrollV : public CScrollV
{
protected:
   virtual bool OnChangePos(void)
     {
      UpdateCotacoesGrid();
      return(true);
     }
   virtual bool OnThumbDragProcess(void)
     {
      CScrollV::OnThumbDragProcess();
     UpdateCotacoesGrid();
     return(true);
    }
};

class CPairsScrollV : public CScrollV
{
protected:
   virtual bool OnChangePos(void)
     {
      UpdatePairsGrid();
      return(true);
     }
   virtual bool OnThumbDragProcess(void)
     {
      CScrollV::OnThumbDragProcess();
      UpdatePairsGrid();
     return(true);
     }
};

class CPairsDetailScrollV : public CScrollV
{
protected:
   virtual bool OnChangePos(void)
     {
      UpdatePairsDetailGrid();
      return(true);
     }
   virtual bool OnThumbDragProcess(void)
     {
      CScrollV::OnThumbDragProcess();
      UpdatePairsDetailGrid();
      return(true);
     }
};

CAppDialog g_app;
CPanel     g_left;
#define TAB_COUNT 8
#define ACTIONS_TAB 1
#define PARES_TAB 2
#define COTACOES_TAB 3
#define CONFIG_TAB 6
CButton    g_tabs[TAB_COUNT];
CLabel     g_icons[TAB_COUNT];
CPanel     g_pages[TAB_COUNT];
CCheckBox g_action_checks[];
string    g_action_symbols[];
int       g_action_total = 0;
CLabel    g_actions_header_sym;
CLabel    g_actions_header_desc;
CButton   g_actions_btn_all;
CButton   g_actions_btn_none;
CButton   g_actions_btn_prev;
CButton   g_actions_btn_next;
CLabel    g_actions_page_label;
int       g_actions_page = 0;
int       g_actions_page_size = 0;
int       g_actions_row_x = 0;
int       g_actions_row_y = 0;
int       g_actions_row_h = 0;
int       g_actions_row_gap = 0;
CEdit     g_quotes_headers[];
CEdit     g_quotes_cells[];
CLabel    g_quotes_empty;
CButton   g_quotes_btn_prev;
CButton   g_quotes_btn_next;
CLabel    g_quotes_page_label;
CLabel    g_quotes_filter_label;
CEdit     g_quotes_filter;
CButton   g_quotes_filter_btn;
CButton   g_quotes_refresh_btn;
CButton   g_quotes_sort_btn;
bool      g_quotes_sort_desc = true;
string    g_selected_symbols[];
string    g_filtered_symbols[];
int       g_quotes_page = 0;
int       g_quotes_cols_per_page = 0;
int       g_quotes_rows = 200;
int       g_quotes_col_w = 80;
int       g_quotes_row_h = 16;
int       g_quotes_row_gap = 2;
int       g_quotes_x = 0;
int       g_quotes_y = 0;
int       g_quotes_w = 0;
int       g_quotes_h = 0;
int       g_quotes_visible_rows = 0;
int       g_quotes_scroll_pos = 0;
int       g_quotes_scroll_w = 14;
int       g_quotes_data_y = 0;
int       g_quotes_date_col_w = 80;
CEdit     g_quotes_date_header;
CEdit     g_quotes_dates[];
CQuotesScrollV g_quotes_scroll;
color     g_quotes_header_bg = (color)0xE6E6E6;
color     g_quotes_row_bg_a = (color)0xFFFFFF;
color     g_quotes_row_bg_b = (color)0xF5F5F5;
color     g_quotes_border = (color)0xD0D0D0;

#define PAIRS_COLS 9
#define PAIRS_DETAIL_COLS 8

CButton   g_pairs_scan_btn;
CLabel    g_pairs_status;
CLabel    g_pairs_metrics;
CEdit     g_pairs_base_display;
CButton   g_pairs_base_drop;
CListView g_pairs_base_list;
bool      g_pairs_base_list_open = false;
CEdit     g_pairs_headers[];
CEdit     g_pairs_cells[];
CLabel    g_pairs_empty;
CPairsScrollV g_pairs_scroll;
int       g_pairs_rows = 200;
int       g_pairs_row_h = 16;
int       g_pairs_row_gap = 2;
int       g_pairs_x = 0;
int       g_pairs_y = 0;
int       g_pairs_w = 0;
int       g_pairs_h = 0;
int       g_pairs_visible_rows = 0;
int       g_pairs_scroll_pos = 0;
int       g_pairs_scroll_w = 14;
int       g_pairs_data_y = 0;
int       g_pairs_col_w[PAIRS_COLS];
color     g_pairs_header_bg = (color)0xE6E6E6;
color     g_pairs_row_bg_a = (color)0xFFFFFF;
color     g_pairs_row_bg_b = (color)0xF5F5F5;
color     g_pairs_border = (color)0xD0D0D0;

CEdit     g_pairs_detail_headers[];
CEdit     g_pairs_detail_cells[];
CLabel    g_pairs_detail_empty;
CPairsDetailScrollV g_pairs_detail_scroll;
int       g_pairs_detail_row_h = 16;
int       g_pairs_detail_row_gap = 2;
int       g_pairs_detail_x = 0;
int       g_pairs_detail_y = 0;
int       g_pairs_detail_w = 0;
int       g_pairs_detail_h = 0;
int       g_pairs_detail_visible_rows = 0;
int       g_pairs_detail_scroll_pos = 0;
int       g_pairs_detail_scroll_w = 14;
int       g_pairs_detail_data_y = 0;
int       g_pairs_detail_col_w[PAIRS_DETAIL_COLS];

CLabel    g_cfg_title;
CLabel    g_cfg_base_label;
CEdit     g_cfg_base_input;
CLabel    g_cfg_windows_label;
CEdit     g_cfg_windows_input;
CLabel    g_cfg_windows_help;
CLabel    g_cfg_windows_current;
CLabel    g_cfg_corr_label;
CEdit     g_cfg_corr_input;
CLabel    g_cfg_adf_label;
CEdit     g_cfg_adf_input;
CLabel    g_cfg_z_label;
CEdit     g_cfg_z_input;
CLabel    g_cfg_beta_label;
CEdit     g_cfg_beta_input;
CLabel    g_cfg_beta_help;
CLabel    g_cfg_half_label;
CEdit     g_cfg_half_input;
CLabel    g_cfg_half_help;
CLabel    g_cfg_half_help2;

#include "LongShortPairsScan.mqh"



string PadRight(const string text, const int width)
{
   string out = text;
   for(int i = StringLen(text); i < width; i++)
      out += " ";
   return(out);
}

void SetAcoesChecked(const bool flag)
{
   for(int i = 0; i < g_action_total; i++)
      g_action_checks[i].Checked(flag);
}

void UpdateAcoesPage(void)
{
   if(g_actions_page_size < 1)
      g_actions_page_size = 1;
   int total_pages = (g_action_total + g_actions_page_size - 1) / g_actions_page_size;
   if(total_pages < 1)
      total_pages = 1;
   if(g_actions_page >= total_pages)
      g_actions_page = total_pages - 1;
   if(g_actions_page < 0)
      g_actions_page = 0;
   const int start = g_actions_page * g_actions_page_size;
   const int end = start + g_actions_page_size - 1;
   for(int i = 0; i < g_action_total; i++)
     {
      if(i >= start && i <= end)
        {
         const int pos = i - start;
         const int row_y = g_actions_row_y + pos * (g_actions_row_h + g_actions_row_gap);
         g_action_checks[i].Move(g_actions_row_x, row_y);
         g_action_checks[i].Visible(true);
        }
      else
        {
         g_action_checks[i].Visible(false);
        }
     }
   const string label = "Pagina " + IntegerToString(g_actions_page + 1) + "/" + IntegerToString(total_pages);
   g_actions_page_label.Text(label);
}

void SetAcoesVisible(const bool flag)
{
   g_actions_btn_all.Visible(flag);
   g_actions_btn_none.Visible(flag);
   g_actions_btn_prev.Visible(flag);
   g_actions_btn_next.Visible(flag);
   g_actions_page_label.Visible(flag);
   g_actions_header_sym.Visible(flag);
   g_actions_header_desc.Visible(flag);
   if(flag)
     {
      UpdateAcoesPage();
     }
   else
     {
      for(int i = 0; i < g_action_total; i++)
         g_action_checks[i].Visible(false);
     }
}

bool InitAcoesTab(const int x, const int y, const int w, const int h)
{
   const int header_h = 20;
   const int row_h = 22;
   const int row_gap = 4;
   const int top_pad = 8;
   const int y_top = y + top_pad;

   g_actions_row_x = x + 12;
   g_actions_row_y = y_top + (header_h * 2) + (row_gap * 2);
   g_actions_row_h = row_h;
   g_actions_row_gap = row_gap;
   const int sym_col_w = 120;

   if(!g_actions_btn_all.Create(0, "acoes_btn_all", 0, x + 12, y_top, x + 12 + 110, y_top + header_h))
      return(false);
   g_actions_btn_all.Text("Marcar tudo");
   g_app.Add(g_actions_btn_all);

   if(!g_actions_btn_none.Create(0, "acoes_btn_none", 0, x + 130, y_top, x + 130 + 120, y_top + header_h))
      return(false);
   g_actions_btn_none.Text("Desmarcar");
   g_app.Add(g_actions_btn_none);

   const int nav_btn_w = 26;
   const int nav_label_w = 80;
   const int nav_gap = 4;
   const int nav_x = x + w - 12 - (nav_btn_w * 2 + nav_label_w + nav_gap * 2);
   if(!g_actions_btn_prev.Create(0, "acoes_btn_prev", 0, nav_x, y_top, nav_x + nav_btn_w, y_top + header_h))
      return(false);
   g_actions_btn_prev.Text("<");
   g_app.Add(g_actions_btn_prev);

   if(!g_actions_page_label.Create(0, "acoes_page", 0, nav_x + nav_btn_w + nav_gap, y_top, nav_x + nav_btn_w + nav_gap + nav_label_w, y_top + header_h))
      return(false);
   g_actions_page_label.Text("Pagina 1/1");
   g_actions_page_label.ColorBackground(clrWhite);
   g_actions_page_label.ColorBorder(clrWhite);
   g_app.Add(g_actions_page_label);

   if(!g_actions_btn_next.Create(0, "acoes_btn_next", 0, nav_x + nav_btn_w + nav_gap + nav_label_w + nav_gap, y_top, nav_x + nav_btn_w + nav_gap + nav_label_w + nav_gap + nav_btn_w, y_top + header_h))
      return(false);
   g_actions_btn_next.Text(">");
   g_app.Add(g_actions_btn_next);

   g_action_total = SymbolsTotal(true);
   if(g_action_total < 0)
      g_action_total = 0;
   g_actions_page_size = 26;
   if(g_actions_page_size < 1)
      g_actions_page_size = 1;
   g_actions_page = 0;

   if(!g_actions_header_sym.Create(0, "acoes_hdr_sym", 0, x + 32, y_top + header_h + 6, x + 32 + sym_col_w, y_top + header_h + 6 + header_h))
      return(false);
   g_actions_header_sym.Text("Simbolo");
   g_actions_header_sym.ColorBackground(clrWhite);
   g_actions_header_sym.ColorBorder(clrWhite);
   g_app.Add(g_actions_header_sym);

   if(!g_actions_header_desc.Create(0, "acoes_hdr_desc", 0, x + 32 + sym_col_w + 12, y_top + header_h + 6, x + w - 12, y_top + header_h + 6 + header_h))
      return(false);
   g_actions_header_desc.Text("Descricao");
   g_actions_header_desc.ColorBackground(clrWhite);
   g_actions_header_desc.ColorBorder(clrWhite);
   g_app.Add(g_actions_header_desc);

   ArrayResize(g_action_symbols, g_action_total);
   ArrayResize(g_action_checks, g_action_total);

   for(int i = 0; i < g_action_total; i++)
     {
      const string sym = SymbolName(i, true);
      string desc = "";
      SymbolInfoString(sym, SYMBOL_DESCRIPTION, desc);
      g_action_symbols[i] = sym;
      const int row_y = y_top + (header_h * 2) + (row_gap * 2) + i * (row_h + row_gap);
      const string name = "acao_cb_" + IntegerToString(i);
      if(!g_action_checks[i].Create(0, name, 0, x + 12, row_y, x + w - 12, row_y + row_h))
         return(false);
      g_action_checks[i].Text(PadRight(sym, 12) + "  " + desc);
      g_action_checks[i].Checked(true);
      g_app.Add(g_action_checks[i]);
     }

   UpdateAcoesPage();

   SetAcoesVisible(false);
   return(true);
}

// Single source of truth for the selected symbols (from "Acoes"/"Cotacoes" selection).
int GetSelectedSymbols(string &out[])
{
   const int count = BuildSelectedSymbols();
   ArrayResize(out, count);
   for(int i = 0; i < count; i++)
      out[i] = g_selected_symbols[i];
   return(count);
}

bool SymbolInList(const string sym, string &list[])
{
   for(int i = 0; i < ArraySize(list); i++)
     {
      if(list[i] == sym)
         return(true);
     }
   return(false);
}

int BuildFilteredSymbols()
{
   const int selected = BuildSelectedSymbols();
   string filter = g_quotes_filter.Text();
   StringTrimLeft(filter);
   StringTrimRight(filter);

   ArrayResize(g_filtered_symbols, 0);
   if(filter == "")
     {
      ArrayResize(g_filtered_symbols, selected);
      for(int i = 0; i < selected; i++)
         g_filtered_symbols[i] = g_selected_symbols[i];
      return(selected);
     }

   string parts[];
   const int total = StringSplit(filter, ',', parts);
   for(int i = 0; i < total; i++)
     {
      string item = parts[i];
      StringTrimLeft(item);
      StringTrimRight(item);
      if(item == "")
         continue;
      string wanted = item;
      StringToUpper(wanted);
      for(int s = 0; s < selected; s++)
        {
         const string sym = g_selected_symbols[s];
         string sym_upper = sym;
         StringToUpper(sym_upper);
         if(sym_upper == wanted && !SymbolInList(sym, g_filtered_symbols))
           {
            const int idx = ArraySize(g_filtered_symbols);
            ArrayResize(g_filtered_symbols, idx + 1);
            g_filtered_symbols[idx] = sym;
            break;
           }
        }
     }
   return(ArraySize(g_filtered_symbols));
}


int GetSortedIndex(const int data_pos, const int total)
{
   if(total <= 0)
      return(-1);
   if(g_quotes_sort_desc)
      return(data_pos);
   return((total - 1) - data_pos);
}

void UpdateSortButtonText()
{
   g_quotes_sort_btn.Text(g_quotes_sort_desc ? "Data desc" : "Data asc");
}

void SetCotacoesVisible(const bool flag)
{
   g_quotes_btn_prev.Visible(flag);
   g_quotes_btn_next.Visible(flag);
   g_quotes_page_label.Visible(flag);
   g_quotes_filter_label.Visible(flag);
   g_quotes_filter.Visible(flag);
   g_quotes_filter_btn.Visible(flag);
   g_quotes_refresh_btn.Visible(flag);
   g_quotes_sort_btn.Visible(flag);
   g_quotes_empty.Visible(flag);
   g_quotes_scroll.Visible(flag);
   g_quotes_date_header.Visible(flag);
   for(int i = 0; i < ArraySize(g_quotes_headers); i++)
      g_quotes_headers[i].Visible(flag);
   for(int i = 0; i < ArraySize(g_quotes_dates); i++)
      g_quotes_dates[i].Visible(flag);
   for(int i = 0; i < ArraySize(g_quotes_cells); i++)
      g_quotes_cells[i].Visible(flag);
}

void SetParesVisible(const bool flag)
{
   g_pairs_scan_btn.Visible(flag);
   g_pairs_status.Visible(flag);
   g_pairs_metrics.Visible(flag);
   g_pairs_base_display.Visible(flag);
   g_pairs_base_drop.Visible(flag);
   g_pairs_base_list.Visible(flag && g_pairs_base_list_open);
   g_pairs_empty.Visible(flag);
   g_pairs_scroll.Visible(flag);
   for(int i = 0; i < ArraySize(g_pairs_headers); i++)
      g_pairs_headers[i].Visible(flag);
   for(int i = 0; i < ArraySize(g_pairs_cells); i++)
      g_pairs_cells[i].Visible(flag);
   g_pairs_detail_empty.Visible(flag);
   g_pairs_detail_scroll.Visible(flag);
   for(int i = 0; i < ArraySize(g_pairs_detail_headers); i++)
      g_pairs_detail_headers[i].Visible(flag);
   for(int i = 0; i < ArraySize(g_pairs_detail_cells); i++)
      g_pairs_detail_cells[i].Visible(flag);
}

void UpdatePairsGrid()
{
   FillMainGrid();
}

void SetConfigVisible(const bool flag)
{
   g_cfg_title.Visible(flag);
   g_cfg_base_label.Visible(flag);
   g_cfg_base_input.Visible(flag);
   g_cfg_windows_label.Visible(flag);
   g_cfg_windows_input.Visible(flag);
   g_cfg_windows_help.Visible(flag);
   g_cfg_windows_current.Visible(flag);
   g_cfg_corr_label.Visible(flag);
   g_cfg_corr_input.Visible(flag);
   g_cfg_adf_label.Visible(flag);
   g_cfg_adf_input.Visible(flag);
   g_cfg_z_label.Visible(flag);
   g_cfg_z_input.Visible(flag);
   g_cfg_beta_label.Visible(flag);
   g_cfg_beta_input.Visible(flag);
   g_cfg_beta_help.Visible(flag);
   g_cfg_half_label.Visible(flag);
   g_cfg_half_input.Visible(flag);
   g_cfg_half_help.Visible(flag);
   g_cfg_half_help2.Visible(flag);
}

void UpdateCotacoesGrid()
{
   const int selected = BuildFilteredSymbols();
   if(g_quotes_cols_per_page < 1)
      g_quotes_cols_per_page = 1;
   if(g_quotes_visible_rows < 1)
      g_quotes_visible_rows = 1;

   int total_pages = (selected + g_quotes_cols_per_page - 1) / g_quotes_cols_per_page;
   if(total_pages < 1)
      total_pages = 1;
   if(g_quotes_page >= total_pages)
      g_quotes_page = total_pages - 1;
   if(g_quotes_page < 0)
      g_quotes_page = 0;

   int max_scroll = g_quotes_rows - g_quotes_visible_rows;
   if(max_scroll < 0)
      max_scroll = 0;
   g_quotes_scroll.MinPos(0);
   g_quotes_scroll.MaxPos(max_scroll);

   g_quotes_scroll_pos = g_quotes_scroll.CurrPos();
   if(g_quotes_scroll_pos > max_scroll)
      g_quotes_scroll_pos = max_scroll;
   if(g_quotes_scroll_pos < 0)
      g_quotes_scroll_pos = 0;
   g_quotes_scroll.CurrPos(g_quotes_scroll_pos);

   if(selected == 0)
     {
      g_quotes_empty.Text("Nenhum ativo selecionado");
      g_quotes_empty.Visible(true);
      g_quotes_page_label.Text("Pagina 0/0");
      g_quotes_date_header.Visible(false);
      for(int i = 0; i < ArraySize(g_quotes_headers); i++)
         g_quotes_headers[i].Visible(false);
      for(int i = 0; i < ArraySize(g_quotes_dates); i++)
         g_quotes_dates[i].Visible(false);
      for(int i = 0; i < ArraySize(g_quotes_cells); i++)
         g_quotes_cells[i].Visible(false);
      return;
     }

   g_quotes_empty.Visible(false);
   g_quotes_date_header.Visible(true);

   datetime times[];
   int got_time = 0;
   if(ArraySize(g_selected_symbols) > 0)
      got_time = CopyTime(g_selected_symbols[0], PERIOD_D1, 0, g_quotes_rows, times);
   if(got_time < 0)
      got_time = 0;

   for(int row = 0; row < g_quotes_visible_rows; row++)
     {
      int data_index = g_quotes_scroll_pos + row;
      if(data_index < got_time)
        {
         const int src = GetSortedIndex(data_index, got_time);
         if(src >= 0 && src < got_time)
            g_quotes_dates[row].Text(TimeToString(times[src], TIME_DATE));
         else
            g_quotes_dates[row].Text("");
        }
      else
         g_quotes_dates[row].Text("");
      g_quotes_dates[row].ColorBackground((data_index % 2 == 0) ? g_quotes_row_bg_a : g_quotes_row_bg_b);
      g_quotes_dates[row].Visible(true);
     }

   const int start = g_quotes_page * g_quotes_cols_per_page;
   const string label = "Pagina " + IntegerToString(g_quotes_page + 1) + "/" + IntegerToString(total_pages);
   g_quotes_page_label.Text(label);

   for(int col = 0; col < g_quotes_cols_per_page; col++)
     {
      const int sym_index = start + col;
      const int header_index = col;
      if(sym_index >= selected)
        {
         g_quotes_headers[header_index].Visible(false);
         for(int row = 0; row < g_quotes_visible_rows; row++)
            g_quotes_cells[row * g_quotes_cols_per_page + col].Visible(false);
         continue;
        }

      const string sym = g_filtered_symbols[sym_index];
      g_quotes_headers[header_index].Text(sym);
      g_quotes_headers[header_index].Visible(true);

      double closes[];
      int got = CopyClose(sym, PERIOD_D1, 0, g_quotes_rows, closes);
      int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      if(got < 0)
         got = 0;

      for(int row = 0; row < g_quotes_visible_rows; row++)
        {
         int data_index = g_quotes_scroll_pos + row;
         int idx = row * g_quotes_cols_per_page + col;
         if(data_index < got)
           {
            const int src = GetSortedIndex(data_index, got);
            if(src >= 0 && src < got)
               g_quotes_cells[idx].Text(DoubleToString(closes[src], digits));
            else
               g_quotes_cells[idx].Text("");
           }
         else
            g_quotes_cells[idx].Text("");
         g_quotes_cells[idx].ColorBackground((data_index % 2 == 0) ? g_quotes_row_bg_a : g_quotes_row_bg_b);
      g_quotes_cells[idx].Visible(true);
     }
   }
}

void BuildPairScanConfig(PairScanConfig &cfg)
{
   int base_window = ParseIntText(g_cfg_base_input.Text(), 180);
   const long list_val = g_pairs_base_list.Value();
   if(list_val > 0)
     {
      base_window = (int)list_val;
     }
   else
     {
      const string text = g_pairs_base_display.Text();
      const int parsed_val = ParseIntText(text, 0);
      if(parsed_val > 0)
         base_window = parsed_val;
     }
   cfg.base_window = base_window;
   cfg.corr_min = ParseDoubleText(g_cfg_corr_input.Text(), 0.75);
   cfg.z_min = ParseDoubleText(g_cfg_z_input.Text(), 0.0);
   cfg.adf_min = ParseDoubleText(g_cfg_adf_input.Text(), 0.0);
   cfg.half_max = ParseDoubleText(g_cfg_half_input.Text(), 0.0);
   cfg.beta_window = ParseIntText(g_cfg_beta_input.Text(), 0);
   cfg.windows_total = ParseWindowsList(g_cfg_windows_input.Text(), cfg.windows);
}

void FillPairsBaseCombo()
{
   g_pairs_base_list.ItemsClear();
   int windows[];
   const int total = ParseWindowsList(g_cfg_windows_input.Text(), windows);
   int base_window = ParseIntText(g_cfg_base_input.Text(), 180);
   for(int i = 0; i < total - 1; i++)
     {
      for(int j = i + 1; j < total; j++)
        {
         if(windows[j] > windows[i])
           {
            const int tmp = windows[i];
            windows[i] = windows[j];
            windows[j] = tmp;
           }
        }
     }
   if(base_window > 0)
      g_pairs_base_list.AddItem(IntegerToString(base_window), base_window);
   for(int i = 0; i < total; i++)
     {
      const int val = windows[i];
      if(val <= 0 || val == base_window)
         continue;
      g_pairs_base_list.AddItem(IntegerToString(val), val);
     }
   g_pairs_base_display.Text(base_window > 0 ? IntegerToString(base_window) : "");
   g_pairs_base_list.SelectByValue(base_window);
   g_pairs_base_list_open = false;
}

void UpdatePairsMetricsLabel()
{
   PairScanConfig cfg;
   BuildPairScanConfig(cfg);
   string text = "Base " + IntegerToString(cfg.base_window);
   text += " | Corr>=" + DoubleToString(cfg.corr_min, 2);
   if(cfg.z_min > 0.0)
      text += " | Z>=" + DoubleToString(cfg.z_min, 2);
   else
      text += " | Z off";
   if(cfg.half_max > 0.0)
      text += " | M.vida<=" + DoubleToString(cfg.half_max, 2);
   else
      text += " | M.vida off";
   if(cfg.adf_min > 0.0)
      text += " | ADF>=" + DoubleToString(cfg.adf_min, 2);
   else
      text += " | ADF off";
   if(cfg.beta_window > 0)
      text += " | BetaWin " + IntegerToString(cfg.beta_window);
   else
      text += " | BetaWin off";
   g_pairs_metrics.Text(text);
}

void ScanPairs()
{
   string symbols[];
   const int symbols_total = GetSelectedSymbols(symbols);
   PairScanConfig cfg;
   BuildPairScanConfig(cfg);

   UpdatePairsMetricsLabel();
   if(ScanPairsBaseWindow(symbols, symbols_total, cfg, 60))
      EventSetTimer(1);
}

bool InitParesTab(const int x, const int y, const int w, const int h)
{
   const int header_h = 18;
   const int top_pad = 8;
   const int y_top = y + top_pad;
   const int left = x + 12;
   const int right = x + w - 12;
   const int btn_w = 110;
   const int btn_h = 24;
   const int base_w = 70;
   const int drop_w = 20;
   const int base_gap = 6;
   const int base_x1 = left;
   const int base_x2 = base_x1 + base_w;
   const int drop_x1 = base_x2;
   const int drop_x2 = drop_x1 + drop_w;
   const int btn_x1 = drop_x2 + base_gap;

   if(!g_pairs_base_display.Create(0, "pairs_base_display", 0, base_x1, y_top, base_x2, y_top + btn_h))
      return(false);
   g_pairs_base_display.ReadOnly(true);
   g_pairs_base_display.Text("");
   g_app.Add(g_pairs_base_display);

   if(!g_pairs_base_drop.Create(0, "pairs_base_drop", 0, drop_x1, y_top, drop_x2, y_top + btn_h))
      return(false);
   g_pairs_base_drop.Text("v");
   g_app.Add(g_pairs_base_drop);

   if(!g_pairs_scan_btn.Create(0, "pairs_scan_btn", 0, btn_x1, y_top, btn_x1 + btn_w, y_top + btn_h))
      return(false);
   g_pairs_scan_btn.Text("Scanear");
   g_app.Add(g_pairs_scan_btn);

   const int metrics_w = 420;
   const int metrics_x1 = right - metrics_w;
   const int status_x1 = btn_x1 + btn_w + 10;
   const int status_x2 = metrics_x1 - 8;
   if(!g_pairs_status.Create(0, "pairs_status", 0, status_x1, y_top, status_x2, y_top + btn_h))
      return(false);
   g_pairs_status.Text("");
   g_pairs_status.ColorBackground(clrWhite);
   g_pairs_status.ColorBorder(clrWhite);
   g_app.Add(g_pairs_status);

   if(!g_pairs_metrics.Create(0, "pairs_metrics", 0, metrics_x1, y_top, right, y_top + btn_h))
      return(false);
   g_pairs_metrics.Text("");
   g_pairs_metrics.ColorBackground(clrWhite);
   g_pairs_metrics.ColorBorder(clrWhite);
   g_app.Add(g_pairs_metrics);

   g_pairs_x = left;
   g_pairs_y = y_top + btn_h + 10;
   const int available_h = h - (g_pairs_y - y) - 12;
   const int grids_gap = 12;
   const int available_w = w - 24;
   int left_w = (int)(available_w * 0.5);
   int right_w = available_w - left_w - grids_gap;
   if(right_w < 160)
     {
      right_w = 160;
      left_w = available_w - right_w - grids_gap;
      if(left_w < 160)
         left_w = 160;
     }
   g_pairs_w = left_w - g_pairs_scroll_w - 4;
   g_pairs_h = available_h;
   g_pairs_visible_rows = (g_pairs_h - header_h - 6) / (g_pairs_row_h + g_pairs_row_gap);
   if(g_pairs_visible_rows < 1)
      g_pairs_visible_rows = 1;
   g_pairs_data_y = g_pairs_y + header_h + 6;

   const int default_w[PAIRS_COLS] = {140, 60, 70, 60, 60, 60, 60, 70, 60};
   int sum_w = 0;
   for(int i = 0; i < PAIRS_COLS; i++)
      sum_w += default_w[i];
   for(int i = 0; i < PAIRS_COLS; i++)
      g_pairs_col_w[i] = default_w[i];
   if(sum_w < g_pairs_w)
      g_pairs_col_w[PAIRS_COLS - 1] += (g_pairs_w - sum_w);

   string col_names[PAIRS_COLS] = {"Par", "Corr", "Score", "Beta", "Z", "M.vida", "ADF", "Status", "Janela"};
   ArrayResize(g_pairs_headers, PAIRS_COLS);
   int x_cursor = g_pairs_x;
   for(int i = 0; i < PAIRS_COLS; i++)
     {
      const int x1 = x_cursor;
      const int x2 = x1 + g_pairs_col_w[i] - 2;
      const string name = "pairs_hdr_" + IntegerToString(i);
      if(!g_pairs_headers[i].Create(0, name, 0, x1, g_pairs_y, x2, g_pairs_y + header_h))
         return(false);
      g_pairs_headers[i].Text(col_names[i]);
      g_pairs_headers[i].ColorBackground(g_pairs_header_bg);
      g_pairs_headers[i].ColorBorder(g_pairs_border);
      g_pairs_headers[i].ReadOnly(true);
      g_app.Add(g_pairs_headers[i]);
      x_cursor += g_pairs_col_w[i];
     }

   ArrayResize(g_pairs_cells, g_pairs_visible_rows * PAIRS_COLS);
   for(int row = 0; row < g_pairs_visible_rows; row++)
     {
      const int y1 = g_pairs_data_y + row * (g_pairs_row_h + g_pairs_row_gap);
      const int y2 = y1 + g_pairs_row_h;
      int cell_x = g_pairs_x;
      for(int col = 0; col < PAIRS_COLS; col++)
        {
         const int x1 = cell_x;
         const int x2 = x1 + g_pairs_col_w[col] - 2;
         const int idx = row * PAIRS_COLS + col;
         if(!g_pairs_cells[idx].Create(0, "pairs_cell_" + IntegerToString(idx), 0, x1, y1, x2, y2))
            return(false);
         g_pairs_cells[idx].Text("");
         g_pairs_cells[idx].ColorBackground((row % 2 == 0) ? g_pairs_row_bg_a : g_pairs_row_bg_b);
         g_pairs_cells[idx].ColorBorder(g_pairs_border);
         g_pairs_cells[idx].ReadOnly(true);
         g_app.Add(g_pairs_cells[idx]);
         cell_x += g_pairs_col_w[col];
        }
     }

   const int scroll_x1 = g_pairs_x + g_pairs_w + 4;
   const int scroll_y1 = g_pairs_data_y;
   const int scroll_x2 = scroll_x1 + g_pairs_scroll_w;
   const int scroll_y2 = g_pairs_data_y + g_pairs_visible_rows * (g_pairs_row_h + g_pairs_row_gap) - g_pairs_row_gap;
   if(!g_pairs_scroll.Create(0, "pairs_scroll", 0, scroll_x1, scroll_y1, scroll_x2, scroll_y2))
      return(false);
   g_pairs_scroll.MinPos(0);
   g_pairs_scroll.MaxPos(0);
   g_pairs_scroll.CurrPos(0);
   g_app.Add(g_pairs_scroll);

   if(!g_pairs_empty.Create(0, "pairs_empty", 0, g_pairs_x, g_pairs_y + header_h + 6, g_pairs_x + g_pairs_w, g_pairs_y + header_h + 24))
      return(false);
   g_pairs_empty.Text("");
   g_pairs_empty.ColorBackground(clrWhite);
   g_pairs_empty.ColorBorder(clrWhite);
   g_app.Add(g_pairs_empty);

   g_pairs_detail_x = g_pairs_x + left_w + grids_gap;
   g_pairs_detail_y = g_pairs_y;
   g_pairs_detail_w = right_w - g_pairs_detail_scroll_w - 4;
   g_pairs_detail_h = available_h;
   g_pairs_detail_visible_rows = (g_pairs_detail_h - header_h - 6) / (g_pairs_detail_row_h + g_pairs_detail_row_gap);
   if(g_pairs_detail_visible_rows < 1)
      g_pairs_detail_visible_rows = 1;
   g_pairs_detail_data_y = g_pairs_detail_y + header_h + 6;

   const int detail_default_w[PAIRS_DETAIL_COLS] = {70, 60, 70, 60, 60, 60, 60, 70};
   int detail_sum = 0;
   for(int i = 0; i < PAIRS_DETAIL_COLS; i++)
      detail_sum += detail_default_w[i];
   for(int i = 0; i < PAIRS_DETAIL_COLS; i++)
      g_pairs_detail_col_w[i] = detail_default_w[i];
   if(detail_sum < g_pairs_detail_w)
      g_pairs_detail_col_w[PAIRS_DETAIL_COLS - 1] += (g_pairs_detail_w - detail_sum);

   string detail_cols[PAIRS_DETAIL_COLS] = {"Janela", "Corr", "Score", "Beta", "Z", "M.vida", "ADF", "Status"};
   ArrayResize(g_pairs_detail_headers, PAIRS_DETAIL_COLS);
   x_cursor = g_pairs_detail_x;
   for(int i = 0; i < PAIRS_DETAIL_COLS; i++)
     {
      const int x1 = x_cursor;
      const int x2 = x1 + g_pairs_detail_col_w[i] - 2;
      const string name = "pairs_detail_hdr_" + IntegerToString(i);
      if(!g_pairs_detail_headers[i].Create(0, name, 0, x1, g_pairs_detail_y, x2, g_pairs_detail_y + header_h))
         return(false);
      g_pairs_detail_headers[i].Text(detail_cols[i]);
      g_pairs_detail_headers[i].ColorBackground(g_pairs_header_bg);
      g_pairs_detail_headers[i].ColorBorder(g_pairs_border);
      g_pairs_detail_headers[i].ReadOnly(true);
      g_app.Add(g_pairs_detail_headers[i]);
      x_cursor += g_pairs_detail_col_w[i];
     }

   ArrayResize(g_pairs_detail_cells, g_pairs_detail_visible_rows * PAIRS_DETAIL_COLS);
   for(int row = 0; row < g_pairs_detail_visible_rows; row++)
     {
      const int y1 = g_pairs_detail_data_y + row * (g_pairs_detail_row_h + g_pairs_detail_row_gap);
      const int y2 = y1 + g_pairs_detail_row_h;
      int cell_x = g_pairs_detail_x;
      for(int col = 0; col < PAIRS_DETAIL_COLS; col++)
        {
         const int x1 = cell_x;
         const int x2 = x1 + g_pairs_detail_col_w[col] - 2;
         const int idx = row * PAIRS_DETAIL_COLS + col;
         if(!g_pairs_detail_cells[idx].Create(0, "pairs_detail_cell_" + IntegerToString(idx), 0, x1, y1, x2, y2))
            return(false);
         g_pairs_detail_cells[idx].Text("");
         g_pairs_detail_cells[idx].ColorBackground((row % 2 == 0) ? g_pairs_row_bg_a : g_pairs_row_bg_b);
         g_pairs_detail_cells[idx].ColorBorder(g_pairs_border);
         g_pairs_detail_cells[idx].ReadOnly(true);
         g_app.Add(g_pairs_detail_cells[idx]);
         cell_x += g_pairs_detail_col_w[col];
        }
     }

   const int detail_scroll_x1 = g_pairs_detail_x + g_pairs_detail_w + 4;
   const int detail_scroll_y1 = g_pairs_detail_data_y;
   const int detail_scroll_x2 = detail_scroll_x1 + g_pairs_detail_scroll_w;
   const int detail_scroll_y2 = g_pairs_detail_data_y + g_pairs_detail_visible_rows * (g_pairs_detail_row_h + g_pairs_detail_row_gap) - g_pairs_detail_row_gap;
   if(!g_pairs_detail_scroll.Create(0, "pairs_detail_scroll", 0, detail_scroll_x1, detail_scroll_y1, detail_scroll_x2, detail_scroll_y2))
      return(false);
   g_pairs_detail_scroll.MinPos(0);
   g_pairs_detail_scroll.MaxPos(0);
   g_pairs_detail_scroll.CurrPos(0);
   g_app.Add(g_pairs_detail_scroll);

   if(!g_pairs_detail_empty.Create(0, "pairs_detail_empty", 0, g_pairs_detail_x, g_pairs_detail_y + header_h + 6, g_pairs_detail_x + g_pairs_detail_w, g_pairs_detail_y + header_h + 24))
      return(false);
   g_pairs_detail_empty.Text("");
   g_pairs_detail_empty.ColorBackground(clrWhite);
   g_pairs_detail_empty.ColorBorder(clrWhite);
   g_app.Add(g_pairs_detail_empty);
   const int list_visible = 6;
   const int list_y1 = y_top + btn_h + 2;
   const int list_y2 = list_y1 + list_visible * (g_pairs_row_h + g_pairs_row_gap) + 2;
   g_pairs_base_list.TotalView(list_visible);
   if(!g_pairs_base_list.Create(0, "pairs_base_list", 0, base_x1, list_y1, drop_x2, list_y2))
      return(false);
   g_pairs_base_list.Hide();
   g_app.Add(g_pairs_base_list);

   SetParesVisible(false);
   return(true);
}

bool InitCotacoesTab(const int x, const int y, const int w, const int h)
{
   const int header_h = 18;
   const int top_pad = 8;
   const int y_top = y + top_pad;

   g_quotes_x = x + 12;
   g_quotes_y = y_top;
   g_quotes_w = w - 24 - g_quotes_scroll_w - 4 - g_quotes_date_col_w;
   g_quotes_h = h - 24;

   g_quotes_cols_per_page = g_quotes_w / g_quotes_col_w;
   if(g_quotes_cols_per_page < 1)
      g_quotes_cols_per_page = 1;

   const int nav_btn_w = 26;
   const int nav_label_w = 80;
   const int nav_gap = 4;
   const int nav_x = x + w - 12 - (nav_btn_w * 2 + nav_label_w + nav_gap * 2);

   const int filter_label_w = 40;
   const int filter_edit_w = 200;
   const int filter_btn_w = 60;
   const int refresh_btn_w = 80;
   const int filter_gap = 6;
   const int sort_btn_w = 80;
   const int sort_x = g_quotes_x;
   const int filter_x = sort_x + sort_btn_w + filter_gap;

   if(!g_quotes_sort_btn.Create(0, "cot_sort_btn", 0, sort_x, y_top, sort_x + sort_btn_w, y_top + header_h))
      return(false);
   UpdateSortButtonText();
   g_app.Add(g_quotes_sort_btn);

   if(!g_quotes_filter_label.Create(0, "cot_filter_lbl", 0, filter_x, y_top, filter_x + filter_label_w, y_top + header_h))
      return(false);
   g_quotes_filter_label.Text("Filtro");
   g_quotes_filter_label.ColorBackground(clrWhite);
   g_quotes_filter_label.ColorBorder(clrWhite);
   g_app.Add(g_quotes_filter_label);

   if(!g_quotes_filter.Create(0, "cot_filter", 0, filter_x + filter_label_w + filter_gap, y_top, filter_x + filter_label_w + filter_gap + filter_edit_w, y_top + header_h))
      return(false);
   g_quotes_filter.Text("");
   g_app.Add(g_quotes_filter);

   if(!g_quotes_filter_btn.Create(0, "cot_filter_btn", 0, filter_x + filter_label_w + filter_gap + filter_edit_w + filter_gap, y_top, filter_x + filter_label_w + filter_gap + filter_edit_w + filter_gap + filter_btn_w, y_top + header_h))
      return(false);
   g_quotes_filter_btn.Text("Filtrar");
   g_app.Add(g_quotes_filter_btn);

   const int refresh_x = nav_x - filter_gap - refresh_btn_w;
   if(!g_quotes_refresh_btn.Create(0, "cot_refresh_btn", 0, refresh_x, y_top, refresh_x + refresh_btn_w, y_top + header_h))
      return(false);
   g_quotes_refresh_btn.Text("Atualizar");
   g_app.Add(g_quotes_refresh_btn);

   if(!g_quotes_btn_prev.Create(0, "cot_btn_prev", 0, nav_x, y_top, nav_x + nav_btn_w, y_top + header_h))
      return(false);
   g_quotes_btn_prev.Text("<");
   g_app.Add(g_quotes_btn_prev);

   if(!g_quotes_page_label.Create(0, "cot_page", 0, nav_x + nav_btn_w + nav_gap, y_top, nav_x + nav_btn_w + nav_gap + nav_label_w, y_top + header_h))
      return(false);
   g_quotes_page_label.Text("Pagina 1/1");
   g_quotes_page_label.ColorBackground(clrWhite);
   g_quotes_page_label.ColorBorder(clrWhite);
   g_app.Add(g_quotes_page_label);

   if(!g_quotes_btn_next.Create(0, "cot_btn_next", 0, nav_x + nav_btn_w + nav_gap + nav_label_w + nav_gap, y_top, nav_x + nav_btn_w + nav_gap + nav_label_w + nav_gap + nav_btn_w, y_top + header_h))
      return(false);
   g_quotes_btn_next.Text(">>");
   g_app.Add(g_quotes_btn_next);

   const int data_y = y_top + header_h + 6 + header_h + 4;
   g_quotes_data_y = data_y;

   g_quotes_visible_rows = (g_quotes_h - (data_y - y_top) - 4) / (g_quotes_row_h + g_quotes_row_gap);
   if(g_quotes_visible_rows < 1)
      g_quotes_visible_rows = 1;

   const int scroll_x1 = x + w - 12 - g_quotes_scroll_w;
   const int scroll_x2 = x + w - 12;
   const int scroll_y1 = data_y;
   const int scroll_y2 = data_y + g_quotes_visible_rows * (g_quotes_row_h + g_quotes_row_gap) - g_quotes_row_gap;
   if(!g_quotes_scroll.Create(0, "cot_scroll", 0, scroll_x1, scroll_y1, scroll_x2, scroll_y2))
      return(false);
   g_quotes_scroll.MinPos(0);
   int max_scroll = g_quotes_rows - g_quotes_visible_rows;
   if(max_scroll < 0)
      max_scroll = 0;
   g_quotes_scroll.MaxPos(max_scroll);
   g_quotes_scroll.CurrPos(0);
   g_app.Add(g_quotes_scroll);

   if(!g_quotes_empty.Create(0, "cot_empty", 0, g_quotes_x, y_top + header_h + 6, g_quotes_x + g_quotes_w, y_top + header_h + 24))
      return(false);
   g_quotes_empty.Text("");
   g_quotes_empty.ColorBackground(clrWhite);
   g_quotes_empty.ColorBorder(clrWhite);
   g_app.Add(g_quotes_empty);

   ArrayResize(g_quotes_headers, g_quotes_cols_per_page);
   if(!g_quotes_date_header.Create(0, "cot_date_hdr", 0, g_quotes_x, y_top + header_h + 6, g_quotes_x + g_quotes_date_col_w - 2, y_top + header_h + 6 + header_h))
      return(false);
   g_quotes_date_header.Text("Data");
   g_quotes_date_header.ColorBackground(g_quotes_header_bg);
   g_quotes_date_header.ColorBorder(g_quotes_border);
   g_quotes_date_header.ReadOnly(true);
   g_app.Add(g_quotes_date_header);

   for(int i = 0; i < g_quotes_cols_per_page; i++)
     {
      const int x1 = g_quotes_x + g_quotes_date_col_w + i * g_quotes_col_w;
      const int x2 = x1 + g_quotes_col_w - 2;
      if(!g_quotes_headers[i].Create(0, "cot_hdr_" + IntegerToString(i), 0, x1, y_top + header_h + 6, x2, y_top + header_h + 6 + header_h))
         return(false);
      g_quotes_headers[i].Text("");
      g_quotes_headers[i].ColorBackground(g_quotes_header_bg);
      g_quotes_headers[i].ColorBorder(g_quotes_border);
      g_quotes_headers[i].ReadOnly(true);
      g_app.Add(g_quotes_headers[i]);
     }

   ArrayResize(g_quotes_dates, g_quotes_visible_rows);
   ArrayResize(g_quotes_cells, g_quotes_cols_per_page * g_quotes_visible_rows);
   for(int row = 0; row < g_quotes_visible_rows; row++)
     {
      const int y1 = data_y + row * (g_quotes_row_h + g_quotes_row_gap);
      const int y2 = y1 + g_quotes_row_h;
      if(!g_quotes_dates[row].Create(0, "cot_date_" + IntegerToString(row), 0, g_quotes_x, y1, g_quotes_x + g_quotes_date_col_w - 2, y2))
         return(false);
      g_quotes_dates[row].Text("");
      g_quotes_dates[row].ColorBackground((row % 2 == 0) ? g_quotes_row_bg_a : g_quotes_row_bg_b);
      g_quotes_dates[row].ColorBorder(g_quotes_border);
      g_quotes_dates[row].ReadOnly(true);
      g_app.Add(g_quotes_dates[row]);

      for(int col = 0; col < g_quotes_cols_per_page; col++)
        {
         const int x1 = g_quotes_x + g_quotes_date_col_w + col * g_quotes_col_w;
         const int x2 = x1 + g_quotes_col_w - 2;
         const int idx = row * g_quotes_cols_per_page + col;
         if(!g_quotes_cells[idx].Create(0, "cot_cell_" + IntegerToString(idx), 0, x1, y1, x2, y2))
            return(false);
         g_quotes_cells[idx].Text("");
         g_quotes_cells[idx].ColorBackground((row % 2 == 0) ? g_quotes_row_bg_a : g_quotes_row_bg_b);
         g_quotes_cells[idx].ColorBorder(g_quotes_border);
         g_quotes_cells[idx].ReadOnly(true);
         g_app.Add(g_quotes_cells[idx]);
        }
     }

   SetCotacoesVisible(false);
   return(true);
}

bool InitConfigTab(const int x, const int y, const int w, const int h)
{
   const int header_h = 18;
   const int top_pad = 8;
   const int y_top = y + top_pad;
   const int left = x + 12;
   const int right = x + w - 12;
   const int col_gap = 16;
   const int label_h = 16;
   const int input_h = 22;

   int y_cursor = y_top;

   if(!g_cfg_title.Create(0, "cfg_title", 0, left, y_cursor, right, y_cursor + header_h))
      return(false);
   g_cfg_title.Text("Configuracoes de metricas");
   g_cfg_title.ColorBackground(clrWhite);
   g_cfg_title.ColorBorder(clrWhite);
   g_app.Add(g_cfg_title);

   y_cursor += header_h + 10;

   const int col_w = (w - 24 - col_gap) / 2;
   const int left_x = left;
   const int right_x = left + col_w + col_gap;

   if(!g_cfg_base_label.Create(0, "cfg_base_lbl", 0, left_x, y_cursor, left_x + col_w, y_cursor + label_h))
      return(false);
   g_cfg_base_label.Text("Janela base (Grid A)");
   g_cfg_base_label.ColorBackground(clrWhite);
   g_cfg_base_label.ColorBorder(clrWhite);
   g_app.Add(g_cfg_base_label);

   if(!g_cfg_windows_label.Create(0, "cfg_windows_lbl", 0, right_x, y_cursor, right_x + col_w, y_cursor + label_h))
      return(false);
   g_cfg_windows_label.Text("Janelas (dias)");
   g_cfg_windows_label.ColorBackground(clrWhite);
   g_cfg_windows_label.ColorBorder(clrWhite);
   g_app.Add(g_cfg_windows_label);

   y_cursor += label_h + 4;

   if(!g_cfg_base_input.Create(0, "cfg_base", 0, left_x, y_cursor, left_x + col_w, y_cursor + input_h))
      return(false);
   g_cfg_base_input.Text("180");
   g_app.Add(g_cfg_base_input);

   if(!g_cfg_windows_input.Create(0, "cfg_windows", 0, right_x, y_cursor, right_x + col_w, y_cursor + input_h))
      return(false);
   g_cfg_windows_input.Text("80,90,100,110,120,140,160,180");
   g_app.Add(g_cfg_windows_input);

   y_cursor += input_h + 6;

   if(!g_cfg_windows_help.Create(0, "cfg_windows_help", 0, right_x, y_cursor, right_x + col_w, y_cursor + label_h))
      return(false);
   g_cfg_windows_help.Text("Informe valores separados por virgula, ex.: 120,140,160.");
   g_cfg_windows_help.ColorBackground(clrWhite);
   g_cfg_windows_help.ColorBorder(clrWhite);
   g_app.Add(g_cfg_windows_help);

   y_cursor += label_h + 4;

   if(!g_cfg_windows_current.Create(0, "cfg_windows_cur", 0, right_x, y_cursor, right_x + col_w, y_cursor + label_h))
      return(false);
   g_cfg_windows_current.Text("Janelas atuais: 80, 90, 100, 110, 120, 140, 160, 180");
   g_cfg_windows_current.ColorBackground(clrWhite);
   g_cfg_windows_current.ColorBorder(clrWhite);
   g_app.Add(g_cfg_windows_current);

   y_cursor += label_h + 12;

   if(!g_cfg_corr_label.Create(0, "cfg_corr_lbl", 0, left_x, y_cursor, left_x + col_w, y_cursor + label_h))
      return(false);
   g_cfg_corr_label.Text("Correlacao minima");
   g_cfg_corr_label.ColorBackground(clrWhite);
   g_cfg_corr_label.ColorBorder(clrWhite);
   g_app.Add(g_cfg_corr_label);

   y_cursor += label_h + 4;

   if(!g_cfg_corr_input.Create(0, "cfg_corr", 0, left_x, y_cursor, left_x + col_w, y_cursor + input_h))
      return(false);
   g_cfg_corr_input.Text("0.75");
   g_app.Add(g_cfg_corr_input);

   y_cursor += input_h + 12;

   const int col3_w = (w - 24 - (col_gap * 2)) / 3;
   const int col1_x = left;
   const int col2_x = col1_x + col3_w + col_gap;
   const int col3_x = col2_x + col3_w + col_gap;

   if(!g_cfg_adf_label.Create(0, "cfg_adf_lbl", 0, col1_x, y_cursor, col1_x + col3_w, y_cursor + label_h))
      return(false);
   g_cfg_adf_label.Text("ADF minimo (%)");
   g_cfg_adf_label.ColorBackground(clrWhite);
   g_cfg_adf_label.ColorBorder(clrWhite);
   g_app.Add(g_cfg_adf_label);

   if(!g_cfg_z_label.Create(0, "cfg_z_lbl", 0, col2_x, y_cursor, col2_x + col3_w, y_cursor + label_h))
      return(false);
   g_cfg_z_label.Text("Z-score minimo (valor absoluto)");
   g_cfg_z_label.ColorBackground(clrWhite);
   g_cfg_z_label.ColorBorder(clrWhite);
   g_app.Add(g_cfg_z_label);

   if(!g_cfg_beta_label.Create(0, "cfg_beta_lbl", 0, col3_x, y_cursor, col3_x + col3_w, y_cursor + label_h))
      return(false);
   g_cfg_beta_label.Text("Janela movel do beta");
   g_cfg_beta_label.ColorBackground(clrWhite);
   g_cfg_beta_label.ColorBorder(clrWhite);
   g_app.Add(g_cfg_beta_label);

   y_cursor += label_h + 4;

   if(!g_cfg_adf_input.Create(0, "cfg_adf", 0, col1_x, y_cursor, col1_x + col3_w, y_cursor + input_h))
      return(false);
   g_cfg_adf_input.Text("95,0");
   g_app.Add(g_cfg_adf_input);

   if(!g_cfg_z_input.Create(0, "cfg_z", 0, col2_x, y_cursor, col2_x + col3_w, y_cursor + input_h))
      return(false);
   g_cfg_z_input.Text("2,0");
   g_app.Add(g_cfg_z_input);

   if(!g_cfg_beta_input.Create(0, "cfg_beta", 0, col3_x, y_cursor, col3_x + col3_w, y_cursor + input_h))
      return(false);
   g_cfg_beta_input.Text("2");
   g_app.Add(g_cfg_beta_input);

   y_cursor += input_h + 6;

   if(!g_cfg_beta_help.Create(0, "cfg_beta_help", 0, col3_x, y_cursor, col3_x + col3_w, y_cursor + label_h))
      return(false);
   g_cfg_beta_help.Text("Usada no grafico de beta movel.");
   g_cfg_beta_help.ColorBackground(clrWhite);
   g_cfg_beta_help.ColorBorder(clrWhite);
   g_app.Add(g_cfg_beta_help);

   y_cursor += label_h + 12;

   if(!g_cfg_half_label.Create(0, "cfg_half_lbl", 0, left_x, y_cursor, left_x + col_w, y_cursor + label_h))
      return(false);
   g_cfg_half_label.Text("Half-life maximo (dias)");
   g_cfg_half_label.ColorBackground(clrWhite);
   g_cfg_half_label.ColorBorder(clrWhite);
   g_app.Add(g_cfg_half_label);

   y_cursor += label_h + 4;

   if(!g_cfg_half_input.Create(0, "cfg_half", 0, left_x, y_cursor, left_x + col_w, y_cursor + input_h))
      return(false);
   g_cfg_half_input.Text("20,0");
   g_app.Add(g_cfg_half_input);

   y_cursor += input_h + 6;

   if(!g_cfg_half_help.Create(0, "cfg_half_help", 0, left_x, y_cursor, right, y_cursor + label_h))
      return(false);
   g_cfg_half_help.Text("Zero desativa o filtro. Limites menores privilegiam pares que");
   g_cfg_half_help.ColorBackground(clrWhite);
   g_cfg_half_help.ColorBorder(clrWhite);
   g_app.Add(g_cfg_half_help);

   y_cursor += label_h + 4;

   if(!g_cfg_half_help2.Create(0, "cfg_half_help2", 0, left_x, y_cursor, right, y_cursor + label_h))
      return(false);
   g_cfg_half_help2.Text("convergem rapido.");
   g_cfg_half_help2.ColorBackground(clrWhite);
   g_cfg_half_help2.ColorBorder(clrWhite);
   g_app.Add(g_cfg_half_help2);

   SetConfigVisible(false);
   return(true);
}
void SwitchTab(const int index)
{
   if(index < 0 || index >= TAB_COUNT)
      return;
   for(int i = 0; i < TAB_COUNT; i++)
      g_pages[i].Visible(i == index);
   SetAcoesVisible(index == ACTIONS_TAB);
   SetParesVisible(index == PARES_TAB);
   SetConfigVisible(index == CONFIG_TAB);
   if(index == COTACOES_TAB)
     {
      SetCotacoesVisible(true);
      UpdateCotacoesGrid();
     }
   else
     {
      SetCotacoesVisible(false);
     }
   if(index == PARES_TAB)
     {
      FillPairsBaseCombo();
      UpdatePairsMetricsLabel();
      UpdatePairsGrid();
      UpdatePairsDetailGrid();
     }
}

int OnInit()
{
   const int w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
   const int h = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   const int panel_w = 190;
   // Keep panel size stable when zooming the chart
   ChartSetInteger(0, CHART_SCALEFIX, false);
   ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

   // Create main app dialog
   if(!g_app.Create(0, "Painel", 0, 0, 0, w, h))
      return(INIT_FAILED);

   // Create left panel
   if(!g_left.Create(0, "left", 0, 0, 0, panel_w, h))
      return(INIT_FAILED);
   g_app.Add(g_left);
   // Create menu tabs
   string tabs[TAB_COUNT] = {"  Inicio", "  Acoes", "  Pares", "  Cotacoes", "  Analise", "  Operacoes", "  Configuracoes", "  Encerradas"};
   string icons[TAB_COUNT] = {"H", "A", "P", "C", "L", "O", "S", "E"};
   const int content_x = panel_w + 12;
   const int content_y = 12;
   const int content_w = w - panel_w - 24;
   const int content_h = h - 24;
   for(int i = 0; i < TAB_COUNT; i++)
     {
      const string pname = "page" + IntegerToString(i);
      if(!g_pages[i].Create(0, pname, 0, content_x, content_y, content_x + content_w, content_y + content_h))
         return(INIT_FAILED);
      g_pages[i].ColorBackground(clrWhite);
      g_pages[i].ColorBorder(clrSilver);
      g_app.Add(g_pages[i]);
      g_pages[i].Visible(i == 0);
     }
   if(!InitAcoesTab(content_x, content_y, content_w, content_h))
      return(INIT_FAILED);
   if(!InitParesTab(content_x, content_y, content_w, content_h))
      return(INIT_FAILED);
   if(!InitCotacoesTab(content_x, content_y, content_w, content_h))
      return(INIT_FAILED);
   if(!InitConfigTab(content_x, content_y, content_w, content_h))
      return(INIT_FAILED);
   const int tab_x = 12;
   const int tab_y = 12;
   const int tab_w = 160;
   const int tab_h = 34;
   const int tab_gap = 6;
   for(int i = 0; i < TAB_COUNT; i++)
     {
      const int y = tab_y + i * (tab_h + tab_gap);
      const string name = "tab" + IntegerToString(i);
      if(!g_tabs[i].Create(0, name, 0, tab_x, y, tab_x + tab_w, y + tab_h))
         return(INIT_FAILED);
      g_tabs[i].Text(tabs[i]);
      g_app.Add(g_tabs[i]);
      if(!g_icons[i].Create(0, name + "_ico", 0, tab_x + 8, y + 6, tab_x + 24, y + 22))
         return(INIT_FAILED);
      g_icons[i].Text(icons[i]);
      g_icons[i].Font("Wingdings");
      g_icons[i].FontSize(12);
      g_app.Add(g_icons[i]);
     }

   // Run dialog
   SwitchTab(0);
   g_app.Run();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   g_app.Destroy(reason);
}

void OnTimer()
{
   if(ProcessPairsScanBatch())
      EventKillTimer();
}

void OnChartEvent(const int id, const long& l, const double& d, const string& s)
{
   if(id == CHARTEVENT_CHART_CHANGE)
      return;
   if(id == CHARTEVENT_MOUSE_WHEEL)
     {
      ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
     }
   g_app.ChartEvent(id, l, d, s);
   if(id == CHARTEVENT_CUSTOM && l == ON_CHANGE && s == "pairs_base_list")
     {
      const string text = g_pairs_base_list.Select();
      if(text != "")
         g_pairs_base_display.Text(text);
      g_pairs_base_list_open = false;
      g_pairs_base_list.Hide();
      UpdatePairsMetricsLabel();
     }
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(s == "pairs_scan_btn")
        {
         ScanPairs();
        }
      else if(s == "pairs_base_drop" || s == "pairs_base_display")
        {
         g_pairs_base_list_open = !g_pairs_base_list_open;
         if(g_pairs_base_list_open)
            g_pairs_base_list.Show();
         else
            g_pairs_base_list.Hide();
        }
      else if(StringFind(s, "pairs_base_listItem") == 0)
        {
         const string item_text = ObjectGetString(0, s, OBJPROP_TEXT);
         if(item_text != "")
           {
            g_pairs_base_list.SelectByText(item_text);
            g_pairs_base_display.Text(item_text);
           }
         g_pairs_base_list_open = false;
         g_pairs_base_list.Hide();
         UpdatePairsMetricsLabel();
        }
      else if(StringFind(s, "pairs_cell_") == 0)
        {
         const int prefix_len = StringLen("pairs_cell_");
         const int idx = (int)StringToInteger(StringSubstr(s, prefix_len));
         const int row = idx / PAIRS_COLS;
         const int data_index = g_pairs_scroll_pos + row;
         PairScanConfig cfg;
         BuildPairScanConfig(cfg);
         FillDetailGridForSelectedPair(data_index, cfg);
        }
      else if(s == "cot_btn_prev")
        {
         if(g_quotes_page > 0)
            g_quotes_page--;
         UpdateCotacoesGrid();
        }
      else if(s == "cot_btn_next")
        {
         if(g_quotes_cols_per_page < 1)
            g_quotes_cols_per_page = 1;
         const int total_pages = (ArraySize(g_filtered_symbols) + g_quotes_cols_per_page - 1) / g_quotes_cols_per_page;
         if(g_quotes_page < total_pages - 1)
            g_quotes_page++;
         UpdateCotacoesGrid();
        }
      else if(s == "cot_filter_btn")
        {
         g_quotes_page = 0;
         UpdateCotacoesGrid();
        }
      else if(s == "cot_refresh_btn")
        {
         g_quotes_scroll_pos = 0;
         g_quotes_scroll.CurrPos(0);
         UpdateCotacoesGrid();
        }
      else if(s == "cot_sort_btn")
        {
         g_quotes_sort_desc = !g_quotes_sort_desc;
         UpdateSortButtonText();
         UpdateCotacoesGrid();
        }
      else if(s == "acoes_btn_all")
         SetAcoesChecked(true);
      else if(s == "acoes_btn_none")
         SetAcoesChecked(false);
      else if(s == "acoes_btn_prev")
        {
         if(g_actions_page > 0)
            g_actions_page--;
         UpdateAcoesPage();
        }
      else if(s == "acoes_btn_next")
        {
         if(g_actions_page_size < 1)
            g_actions_page_size = 1;
         const int total_pages = (g_action_total + g_actions_page_size - 1) / g_actions_page_size;
         if(g_actions_page < total_pages - 1)
            g_actions_page++;
         UpdateAcoesPage();
        }
      else
        {
         for(int i = 0; i < TAB_COUNT; i++)
           {
            if(s == "tab" + IntegerToString(i))
              {
               SwitchTab(i);
               break;
              }
           }
        }
     }

   if((id == CHARTEVENT_OBJECT_CHANGE || id == CHARTEVENT_OBJECT_ENDEDIT) &&
      StringFind(s, "pairs_base_combo") == 0)
     {
      UpdatePairsMetricsLabel();
     }
}





















