#property strict
#property version   "1.000"

#include <Controls/Dialog.mqh>
#include <Controls/Panel.mqh>
#include <Controls/Label.mqh>
#include <Controls/Edit.mqh>
#include <Controls/Button.mqh>

CAppDialog g_app;
CPanel g_card;
CLabel g_title;
CLabel g_subtitle;

CPanel g_sell_card;
CPanel g_buy_card;
CLabel g_sell_card_title;
CLabel g_buy_card_title;
CLabel g_sell_price_label;
CLabel g_buy_price_label;
CLabel g_sell_price_value;
CLabel g_buy_price_value;
CLabel g_sell_qty_label;
CLabel g_buy_qty_label;
CEdit  g_sell_qty_input;
CEdit  g_buy_qty_input;
CButton g_sell_qty_up;
CButton g_sell_qty_down;
CButton g_buy_qty_up;
CButton g_buy_qty_down;
CLabel g_sell_total_label;
CLabel g_buy_total_label;
CLabel g_sell_total_value;
CLabel g_buy_total_value;

CLabel g_sell_label;
CEdit  g_sell_input;
CLabel g_buy_label;
CEdit  g_buy_input;
CLabel g_strategy_label;
CEdit  g_strategy_input;
CLabel g_follow_label;
CEdit  g_follow_input;

CButton g_submit_btn;
CButton g_clear_btn;
CLabel  g_status_label;

void SetStatus(const string text, const color c)
{
   g_status_label.Text(text);
   g_status_label.Color(c);
}

bool UpdateSymbolPrice(CEdit &field, CLabel &price_out, const bool is_buy)
{
   string sym = field.Text();
   StringTrimLeft(sym);
   StringTrimRight(sym);
   StringToUpper(sym);
   field.Text(sym);
   if(sym == "")
     {
      price_out.Text("--");
      return(false);
     }

   if(!SymbolSelect(sym, true))
     {
      price_out.Text("--");
      SetStatus("Simbolo nao encontrado: " + sym, clrRed);
      return(false);
     }

   double price = 0.0;
   if(is_buy)
      price = SymbolInfoDouble(sym, SYMBOL_ASK);
   else
      price = SymbolInfoDouble(sym, SYMBOL_BID);
   int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   price_out.Text(FormatMoney(price, digits));
   return(true);
}

bool TryParseDouble(const string text, double &out)
{
   string t = text;
   StringTrimLeft(t);
   StringTrimRight(t);
   StringReplace(t, "R$", "");
   StringReplace(t, " ", "");
   StringTrimLeft(t);
   StringTrimRight(t);
   if(t == "")
      return(false);
   out = StringToDouble(t);
   return(true);
}

string FormatMoney(const double value, const int digits)
{
   return(StringFormat("R$ %.*f", digits, value));
}

void UpdateTotal(CLabel &price_label, CEdit &qty_field, CLabel &total_out)
{
   double price = 0.0;
   double qty = 0.0;
   if(!TryParseDouble(price_label.Text(), price) || !TryParseDouble(qty_field.Text(), qty))
     {
      total_out.Text("--");
      return;
     }
   total_out.Text(FormatMoney(price * qty, 2));
}

void UpdateQtyByDelta(CEdit &qty_field, const double delta)
{
   double qty = 0.0;
   if(!TryParseDouble(qty_field.Text(), qty))
      qty = 0.0;
   qty += delta;
   if(qty < 0.0)
      qty = 0.0;
   qty_field.Text(DoubleToString(qty, 0));
}

bool InitBoleta(const int w, const int h)
{
   const int pad = 20;
   const int card_w = MathMin(w - (pad * 2), 520);
   const int card_h = 400;
   int card_x = (w - card_w) / 2;
   int card_y = (h - card_h) / 2;
   if(card_x < pad)
      card_x = pad;
   if(card_y < pad)
      card_y = pad;

   if(!g_card.Create(0, "boleta_card", 0, card_x, card_y, card_x + card_w, card_y + card_h))
      return(false);
   g_card.ColorBackground(clrWhite);
   g_card.ColorBorder(clrSilver);
   g_app.Add(g_card);

   const int left = card_x + 16;
   const int right = card_x + card_w - 16;
   int y = card_y + 16;

   if(!g_title.Create(0, "boleta_title", 0, left, y, right, y + 22))
      return(false);
   g_title.Text("Boleta Long/Short");
   g_title.FontSize(12);
   g_title.ColorBackground(clrWhite);
   g_title.ColorBorder(clrWhite);
   g_app.Add(g_title);

   y += 22;
   if(!g_subtitle.Create(0, "boleta_subtitle", 0, left, y, right, y + 18))
      return(false);
   g_subtitle.Text("Ativo vendido, ativo comprado, quantidade e estrategia");
   g_subtitle.Color(clrGray);
   g_subtitle.ColorBackground(clrWhite);
   g_subtitle.ColorBorder(clrWhite);
   g_app.Add(g_subtitle);

   y += 28;
   const int label_w = 140;
   const int input_h = 22;
   const int row_gap = 8;

   const int card_gap = 12;
   const int asset_card_w = (card_w - 32 - card_gap) / 2;
   const int asset_card_h = 180;
   const int sell_x1 = left;
   const int sell_x2 = left + asset_card_w;
   const int buy_x1 = sell_x2 + card_gap;
   const int buy_x2 = buy_x1 + asset_card_w;

   if(!g_sell_card.Create(0, "sell_card", 0, sell_x1, y, sell_x2, y + asset_card_h))
      return(false);
   g_sell_card.ColorBackground(clrWhite);
   g_sell_card.ColorBorder(clrSilver);
   g_app.Add(g_sell_card);

   if(!g_buy_card.Create(0, "buy_card", 0, buy_x1, y, buy_x2, y + asset_card_h))
      return(false);
   g_buy_card.ColorBackground(clrWhite);
   g_buy_card.ColorBorder(clrSilver);
   g_app.Add(g_buy_card);

   if(!g_sell_card_title.Create(0, "sell_card_title", 0, sell_x1 + 10, y + 8, sell_x2 - 10, y + 26))
      return(false);
   g_sell_card_title.Text("Vender");
   g_sell_card_title.Color(clrRed);
   g_sell_card_title.ColorBackground(clrWhite);
   g_sell_card_title.ColorBorder(clrWhite);
   g_app.Add(g_sell_card_title);

   if(!g_buy_card_title.Create(0, "buy_card_title", 0, buy_x1 + 10, y + 8, buy_x2 - 10, y + 26))
      return(false);
   g_buy_card_title.Text("Comprar");
   g_buy_card_title.Color(clrGreen);
   g_buy_card_title.ColorBackground(clrWhite);
   g_buy_card_title.ColorBorder(clrWhite);
   g_app.Add(g_buy_card_title);

   if(!g_sell_label.Create(0, "sell_label", 0, sell_x1 + 10, y + 30, sell_x1 + label_w, y + 30 + input_h))
      return(false);
   g_sell_label.Text("Ativo");
   g_sell_label.ColorBackground(clrWhite);
   g_sell_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_label);

   if(!g_sell_input.Create(0, "sell_input", 0, sell_x1 + 10, y + 52, sell_x2 - 10, y + 52 + input_h))
      return(false);
   g_sell_input.Text("");
   g_app.Add(g_sell_input);

   const int btn_w = 18;
   const int btn_h = 10;
   const int btn_gap = 2;
   const int qty_input_w = asset_card_w - 10 - 10 - btn_w;

   if(!g_sell_qty_label.Create(0, "sell_qty_label", 0, sell_x1 + 10, y + 78, sell_x1 + label_w, y + 78 + input_h))
      return(false);
   g_sell_qty_label.Text("Quantidade");
   g_sell_qty_label.ColorBackground(clrWhite);
   g_sell_qty_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_qty_label);

   if(!g_sell_qty_input.Create(0, "sell_qty_input", 0, sell_x1 + 10, y + 100, sell_x1 + 10 + qty_input_w, y + 100 + input_h))
      return(false);
   g_sell_qty_input.Text("");
   g_app.Add(g_sell_qty_input);

   if(!g_sell_qty_up.Create(0, "sell_qty_up", 0, sell_x1 + 10 + qty_input_w + 2, y + 100, sell_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h))
      return(false);
   g_sell_qty_up.Text("^");
   g_app.Add(g_sell_qty_up);

   if(!g_sell_qty_down.Create(0, "sell_qty_down", 0, sell_x1 + 10 + qty_input_w + 2, y + 100 + btn_h + btn_gap, sell_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h + btn_gap + btn_h))
      return(false);
   g_sell_qty_down.Text("v");
   g_app.Add(g_sell_qty_down);

   if(!g_sell_price_label.Create(0, "sell_price_label", 0, sell_x1 + 10, y + 126, sell_x1 + label_w, y + 126 + input_h))
      return(false);
   g_sell_price_label.Text("Preco");
   g_sell_price_label.ColorBackground(clrWhite);
   g_sell_price_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_price_label);

   if(!g_sell_price_value.Create(0, "sell_price_value", 0, sell_x1 + 70, y + 126, sell_x2 - 10, y + 126 + input_h))
      return(false);
   g_sell_price_value.Text("--");
   g_sell_price_value.ColorBackground(clrWhite);
   g_sell_price_value.ColorBorder(clrWhite);
   g_app.Add(g_sell_price_value);

   if(!g_buy_label.Create(0, "buy_label", 0, buy_x1 + 10, y + 30, buy_x1 + label_w, y + 30 + input_h))
      return(false);
   g_buy_label.Text("Ativo");
   g_buy_label.ColorBackground(clrWhite);
   g_buy_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_label);

   if(!g_buy_input.Create(0, "buy_input", 0, buy_x1 + 10, y + 52, buy_x2 - 10, y + 52 + input_h))
      return(false);
   g_buy_input.Text("");
   g_app.Add(g_buy_input);

   if(!g_buy_qty_label.Create(0, "buy_qty_label", 0, buy_x1 + 10, y + 78, buy_x1 + label_w, y + 78 + input_h))
      return(false);
   g_buy_qty_label.Text("Quantidade");
   g_buy_qty_label.ColorBackground(clrWhite);
   g_buy_qty_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_qty_label);

   if(!g_buy_qty_input.Create(0, "buy_qty_input", 0, buy_x1 + 10, y + 100, buy_x1 + 10 + qty_input_w, y + 100 + input_h))
      return(false);
   g_buy_qty_input.Text("");
   g_app.Add(g_buy_qty_input);

   if(!g_buy_qty_up.Create(0, "buy_qty_up", 0, buy_x1 + 10 + qty_input_w + 2, y + 100, buy_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h))
      return(false);
   g_buy_qty_up.Text("^");
   g_app.Add(g_buy_qty_up);

   if(!g_buy_qty_down.Create(0, "buy_qty_down", 0, buy_x1 + 10 + qty_input_w + 2, y + 100 + btn_h + btn_gap, buy_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h + btn_gap + btn_h))
      return(false);
   g_buy_qty_down.Text("v");
   g_app.Add(g_buy_qty_down);

   if(!g_buy_price_label.Create(0, "buy_price_label", 0, buy_x1 + 10, y + 126, buy_x1 + label_w, y + 126 + input_h))
      return(false);
   g_buy_price_label.Text("Preco");
   g_buy_price_label.ColorBackground(clrWhite);
   g_buy_price_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_price_label);

   if(!g_buy_price_value.Create(0, "buy_price_value", 0, buy_x1 + 70, y + 126, buy_x2 - 10, y + 126 + input_h))
      return(false);
   g_buy_price_value.Text("--");
   g_buy_price_value.ColorBackground(clrWhite);
   g_buy_price_value.ColorBorder(clrWhite);
   g_app.Add(g_buy_price_value);

   const int total_row_y = y + 150;
   if(!g_sell_total_label.Create(0, "sell_total_label", 0, sell_x1 + 10, total_row_y, sell_x1 + label_w, total_row_y + input_h))
      return(false);
   g_sell_total_label.Text("Total venda");
   g_sell_total_label.ColorBackground(clrWhite);
   g_sell_total_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_total_label);

   if(!g_sell_total_value.Create(0, "sell_total_value", 0, sell_x1 + 100, total_row_y, sell_x2 - 10, total_row_y + input_h))
      return(false);
   g_sell_total_value.Text("--");
   g_sell_total_value.ColorBackground(clrWhite);
   g_sell_total_value.ColorBorder(clrWhite);
   g_app.Add(g_sell_total_value);

   if(!g_buy_total_label.Create(0, "buy_total_label", 0, buy_x1 + 10, total_row_y, buy_x1 + label_w, total_row_y + input_h))
      return(false);
   g_buy_total_label.Text("Total compra");
   g_buy_total_label.ColorBackground(clrWhite);
   g_buy_total_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_total_label);

   if(!g_buy_total_value.Create(0, "buy_total_value", 0, buy_x1 + 100, total_row_y, buy_x2 - 10, total_row_y + input_h))
      return(false);
   g_buy_total_value.Text("--");
   g_buy_total_value.ColorBackground(clrWhite);
   g_buy_total_value.ColorBorder(clrWhite);
   g_app.Add(g_buy_total_value);

   y += asset_card_h + 8;
   if(!g_strategy_label.Create(0, "strategy_label", 0, left, y, left + label_w, y + input_h))
      return(false);
   g_strategy_label.Text("Estrategia");
   g_strategy_label.ColorBackground(clrWhite);
   g_strategy_label.ColorBorder(clrWhite);
   g_app.Add(g_strategy_label);

   if(!g_strategy_input.Create(0, "strategy_input", 0, left + label_w + 8, y, right, y + input_h))
      return(false);
   g_strategy_input.Text("");
   g_app.Add(g_strategy_input);

   y += input_h + row_gap;
   if(!g_follow_label.Create(0, "follow_label", 0, left, y, left + label_w, y + input_h))
      return(false);
   g_follow_label.Text("Acompanhamento");
   g_follow_label.ColorBackground(clrWhite);
   g_follow_label.ColorBorder(clrWhite);
   g_app.Add(g_follow_label);

   if(!g_follow_input.Create(0, "follow_input", 0, left + label_w + 8, y, right, y + input_h))
      return(false);
   g_follow_input.Text("");
   g_app.Add(g_follow_input);

   y += input_h + 14;
   const int btn_action_w = 120;
   if(!g_submit_btn.Create(0, "btn_submit", 0, right - (btn_action_w * 2 + 8), y, right - btn_action_w - 8, y + 26))
      return(false);
   g_submit_btn.Text("Enviar");
   g_app.Add(g_submit_btn);

   if(!g_clear_btn.Create(0, "btn_clear", 0, right - btn_action_w, y, right, y + 26))
      return(false);
   g_clear_btn.Text("Limpar");
   g_app.Add(g_clear_btn);

   y += 34;
   if(!g_status_label.Create(0, "status_label", 0, left, y, right, y + 18))
      return(false);
   g_status_label.Text("Pronto para iniciar.");
   g_status_label.ColorBackground(clrWhite);
   g_status_label.ColorBorder(clrWhite);
   g_app.Add(g_status_label);

   return(true);
}

int OnInit()
{
   const int w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
   const int h = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);

   ChartSetInteger(0, CHART_SCALEFIX, false);
   ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

   if(!g_app.Create(0, "Painel", 0, 0, 0, w, h))
      return(INIT_FAILED);
   if(!InitBoleta(w, h))
      return(INIT_FAILED);

   g_app.Run();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   g_app.Destroy(reason);
}

void OnChartEvent(const int id, const long& l, const double& d, const string& s)
{
   g_app.ChartEvent(id, l, d, s);
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      if(s == "sell_input")
        {
         if(UpdateSymbolPrice(g_sell_input, g_sell_price_value, false))
            UpdateTotal(g_sell_price_value, g_sell_qty_input, g_sell_total_value);
        }
      else if(s == "buy_input")
        {
         if(UpdateSymbolPrice(g_buy_input, g_buy_price_value, true))
            UpdateTotal(g_buy_price_value, g_buy_qty_input, g_buy_total_value);
        }
      else if(s == "sell_qty_input")
         UpdateTotal(g_sell_price_value, g_sell_qty_input, g_sell_total_value);
      else if(s == "buy_qty_input")
         UpdateTotal(g_buy_price_value, g_buy_qty_input, g_buy_total_value);
      return;
     }

   if(id != CHARTEVENT_OBJECT_CLICK)
      return;
   if(s == "btn_clear")
     {
      g_sell_input.Text("");
      g_buy_input.Text("");
      g_sell_qty_input.Text("");
      g_buy_qty_input.Text("");
      g_strategy_input.Text("");
      g_follow_input.Text("");
      g_sell_price_value.Text("--");
      g_buy_price_value.Text("--");
      g_sell_total_value.Text("--");
      g_buy_total_value.Text("--");
      SetStatus("Campos limpos.", clrGray);
     }
   else if(s == "sell_qty_up")
     {
      UpdateQtyByDelta(g_sell_qty_input, 100.0);
      UpdateTotal(g_sell_price_value, g_sell_qty_input, g_sell_total_value);
     }
   else if(s == "sell_qty_down")
     {
      UpdateQtyByDelta(g_sell_qty_input, -100.0);
      UpdateTotal(g_sell_price_value, g_sell_qty_input, g_sell_total_value);
     }
   else if(s == "buy_qty_up")
     {
      UpdateQtyByDelta(g_buy_qty_input, 100.0);
      UpdateTotal(g_buy_price_value, g_buy_qty_input, g_buy_total_value);
     }
   else if(s == "buy_qty_down")
     {
      UpdateQtyByDelta(g_buy_qty_input, -100.0);
      UpdateTotal(g_buy_price_value, g_buy_qty_input, g_buy_total_value);
     }
   else if(s == "btn_submit")
     {
      SetStatus("Entrada registrada (simulacao).", clrDarkGreen);
     }
}




