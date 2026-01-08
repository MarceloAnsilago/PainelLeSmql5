// Reusable Z-score mini chart for MQL5 panels.
#ifndef ZSCORE_CHART_MQH
#define ZSCORE_CHART_MQH

#include <Controls/Dialog.mqh>
#include <Controls/Label.mqh>
#include <Controls/Panel.mqh>
#include <Controls/Edit.mqh>

const color Z_BLUE   = (color)0xD77800; // RGB #0078D7 in BGR
const color Z_GRAY   = (color)0xC8C8C8;
const color Z_RED    = (color)0x0000FF; // red in BGR (RGB 255,0,0)
const color Z_ORANGE = (color)0x00A5FF; // orange in BGR (RGB 255,165,0)

class CZScoreChart
  {
private:
   string  m_prefix;
   CLabel  m_title;
   CPanel  m_bg;
   CEdit   m_dots[];
   CPanel  m_line_dots[];
   CPanel  m_line_zero;
   CPanel  m_line_p2;
   CPanel  m_line_m2;
   CPanel  m_dots_p3[];
   CPanel  m_dots_m3[];
   CLabel  m_lbl_p3;
   CLabel  m_lbl_p2;
   CLabel  m_lbl_zero;
   CLabel  m_lbl_m2;
   CLabel  m_lbl_m3;
   int     m_max_points;
   int     m_line_max;
   int     m_x;
   int     m_title_y;
   int     m_title_h;
   int     m_plot_y;
   int     m_w;
   int     m_h;

public:
   bool Create(CAppDialog &app,
               const string prefix,
               const int x,
               const int title_y,
               const int w,
               const int plot_y,
               const int plot_h,
               const int title_h = 18,
               const int max_points = 120,
               const int line_max = 2000)
     {
      m_prefix = prefix;
      m_x = x;
      m_title_y = title_y;
      m_title_h = title_h;
      m_plot_y = plot_y;
      m_w = w;
      m_h = plot_h;
      m_max_points = max_points;
      m_line_max = line_max;

      if(!m_title.Create(0, m_prefix + "_title", 0, m_x, m_title_y, m_x + m_w, m_title_y + m_title_h))
         return(false);
      m_title.Text("Z-score");
      m_title.ColorBackground(clrWhite);
      m_title.ColorBorder(clrWhite);
      app.Add(m_title);

      if(!m_bg.Create(0, m_prefix + "_bg", 0, m_x, m_plot_y, m_x + m_w, m_plot_y + m_h))
         return(false);
      m_bg.ColorBackground(clrWhite);
      m_bg.ColorBorder((color)0xD0D0D0);
      app.Add(m_bg);

      const int label_w = 24;
      const int label_h = 14;
      const int label_x = m_x + 4;
      const int label_y = m_plot_y + 4;
      if(!m_lbl_p3.Create(0, m_prefix + "_lbl_p3", 0, label_x, label_y, label_x + label_w, label_y + label_h))
         return(false);
      m_lbl_p3.Text("+3");
      m_lbl_p3.Color(Z_ORANGE);
      m_lbl_p3.ColorBackground(clrWhite);
      m_lbl_p3.ColorBorder(clrWhite);
      m_lbl_p3.Visible(false);
      app.Add(m_lbl_p3);

      if(!m_lbl_p2.Create(0, m_prefix + "_lbl_p2", 0, label_x, label_y, label_x + label_w, label_y + label_h))
         return(false);
      m_lbl_p2.Text("+2");
      m_lbl_p2.Color(Z_RED);
      m_lbl_p2.ColorBackground(clrWhite);
      m_lbl_p2.ColorBorder(clrWhite);
      m_lbl_p2.Visible(false);
      app.Add(m_lbl_p2);

      if(!m_lbl_zero.Create(0, m_prefix + "_lbl_zero", 0, label_x, label_y, label_x + label_w, label_y + label_h))
         return(false);
      m_lbl_zero.Text("0");
      m_lbl_zero.Color(Z_GRAY);
      m_lbl_zero.ColorBackground(clrWhite);
      m_lbl_zero.ColorBorder(clrWhite);
      m_lbl_zero.Visible(false);
      app.Add(m_lbl_zero);

      if(!m_lbl_m2.Create(0, m_prefix + "_lbl_m2", 0, label_x, label_y, label_x + label_w, label_y + label_h))
         return(false);
      m_lbl_m2.Text("-2");
      m_lbl_m2.Color(Z_RED);
      m_lbl_m2.ColorBackground(clrWhite);
      m_lbl_m2.ColorBorder(clrWhite);
      m_lbl_m2.Visible(false);
      app.Add(m_lbl_m2);

      if(!m_lbl_m3.Create(0, m_prefix + "_lbl_m3", 0, label_x, label_y, label_x + label_w, label_y + label_h))
         return(false);
      m_lbl_m3.Text("-3");
      m_lbl_m3.Color(Z_ORANGE);
      m_lbl_m3.ColorBackground(clrWhite);
      m_lbl_m3.ColorBorder(clrWhite);
      m_lbl_m3.Visible(false);
      app.Add(m_lbl_m3);

      if(!m_line_zero.Create(0, m_prefix + "_line_zero", 0, m_x, m_plot_y, m_x + m_w, m_plot_y + 1))
         return(false);
      m_line_zero.ColorBackground(Z_GRAY);
      m_line_zero.ColorBorder(Z_GRAY);
      m_line_zero.Visible(false);
      app.Add(m_line_zero);

      if(!m_line_p2.Create(0, m_prefix + "_line_p2", 0, m_x, m_plot_y, m_x + m_w, m_plot_y + 1))
         return(false);
      m_line_p2.ColorBackground(Z_RED);
      m_line_p2.ColorBorder(Z_RED);
      m_line_p2.Visible(false);
      app.Add(m_line_p2);

      if(!m_line_m2.Create(0, m_prefix + "_line_m2", 0, m_x, m_plot_y, m_x + m_w, m_plot_y + 1))
         return(false);
      m_line_m2.ColorBackground(Z_RED);
      m_line_m2.ColorBorder(Z_RED);
      m_line_m2.Visible(false);
      app.Add(m_line_m2);

      const int dotted_count = 80;
      ArrayResize(m_dots_p3, dotted_count);
      ArrayResize(m_dots_m3, dotted_count);
      for(int i = 0; i < dotted_count; i++)
        {
         const string name_p3 = m_prefix + "_dot_p3_" + IntegerToString(i);
         if(!m_dots_p3[i].Create(0, name_p3, 0, m_x, m_plot_y, m_x + 2, m_plot_y + 2))
            return(false);
         m_dots_p3[i].ColorBackground(Z_ORANGE);
         m_dots_p3[i].ColorBorder(Z_ORANGE);
         m_dots_p3[i].Visible(false);
         app.Add(m_dots_p3[i]);

         const string name_m3 = m_prefix + "_dot_m3_" + IntegerToString(i);
         if(!m_dots_m3[i].Create(0, name_m3, 0, m_x, m_plot_y, m_x + 2, m_plot_y + 2))
            return(false);
         m_dots_m3[i].ColorBackground(Z_ORANGE);
         m_dots_m3[i].ColorBorder(Z_ORANGE);
         m_dots_m3[i].Visible(false);
         app.Add(m_dots_m3[i]);
        }

      ArrayResize(m_dots, m_max_points);
      for(int i = 0; i < m_max_points; i++)
        {
         const string name = m_prefix + "_dot_" + IntegerToString(i);
         if(!m_dots[i].Create(0, name, 0, m_x, m_plot_y, m_x + 2, m_plot_y + 2))
            return(false);
         m_dots[i].Text("");
         m_dots[i].ColorBackground(clrWhite);
         m_dots[i].ColorBorder(Z_BLUE);
         m_dots[i].ReadOnly(true);
         m_dots[i].Visible(false);
         app.Add(m_dots[i]);
        }

      ArrayResize(m_line_dots, m_line_max);
      for(int i = 0; i < m_line_max; i++)
        {
         const string name = m_prefix + "_line_" + IntegerToString(i);
         if(!m_line_dots[i].Create(0, name, 0, m_x, m_plot_y, m_x + 1, m_plot_y + 1))
            return(false);
         m_line_dots[i].ColorBackground(Z_BLUE);
         m_line_dots[i].ColorBorder(Z_BLUE);
         m_line_dots[i].Visible(false);
         app.Add(m_line_dots[i]);
        }

      return(true);
     }

   void SetVisible(const bool flag)
     {
      m_title.Visible(flag);
      m_bg.Visible(flag);
      for(int i = 0; i < ArraySize(m_dots); i++)
         m_dots[i].Visible(flag);
      for(int i = 0; i < ArraySize(m_line_dots); i++)
         m_line_dots[i].Visible(flag);
      m_line_zero.Visible(flag);
      m_line_p2.Visible(flag);
      m_line_m2.Visible(flag);
      for(int i = 0; i < ArraySize(m_dots_p3); i++)
         m_dots_p3[i].Visible(flag);
      for(int i = 0; i < ArraySize(m_dots_m3); i++)
         m_dots_m3[i].Visible(flag);
      m_lbl_p3.Visible(flag);
      m_lbl_p2.Visible(flag);
      m_lbl_zero.Visible(flag);
      m_lbl_m2.Visible(flag);
      m_lbl_m3.Visible(flag);
     }

   void Draw(const double &zvals[], const int total, const string title)
     {
      const int pad = 6;
      if(total < 2)
        {
         for(int i = 0; i < ArraySize(m_dots); i++)
            m_dots[i].Visible(false);
         for(int i = 0; i < ArraySize(m_line_dots); i++)
            m_line_dots[i].Visible(false);
         m_line_zero.Visible(false);
         m_line_p2.Visible(false);
         m_line_m2.Visible(false);
         for(int i = 0; i < ArraySize(m_dots_p3); i++)
            m_dots_p3[i].Visible(false);
         for(int i = 0; i < ArraySize(m_dots_m3); i++)
            m_dots_m3[i].Visible(false);
         m_lbl_p3.Visible(false);
         m_lbl_p2.Visible(false);
         m_lbl_zero.Visible(false);
         m_lbl_m2.Visible(false);
         m_lbl_m3.Visible(false);
         m_title.Text(title);
         return;
        }

      double min_v = zvals[0];
      double max_v = zvals[0];
      for(int i = 1; i < total; i++)
        {
         if(zvals[i] < min_v)
            min_v = zvals[i];
         if(zvals[i] > max_v)
            max_v = zvals[i];
        }

      const double max_abs = 3.0;
      min_v = -max_abs;
      max_v = max_abs;
      const double range = max_v - min_v;

      const int margin_y = 14;
      const int plot_x1 = m_x + pad;
      const int plot_y1 = m_plot_y + pad + margin_y;
      const int plot_x2 = m_x + m_w - pad - 1;
      const int plot_y2 = m_plot_y + m_h - pad - 1 - margin_y;
      const int line_h = 2;

      const int y_zero = plot_y1 + (int)(((max_v - 0.0) / range) * (plot_y2 - plot_y1));
      const int y_p2 = plot_y1 + (int)(((max_v - 2.0) / range) * (plot_y2 - plot_y1));
      const int y_m2 = plot_y1 + (int)(((max_v - -2.0) / range) * (plot_y2 - plot_y1));
      const int y_p3 = plot_y1 + (int)(((max_v - 3.0) / range) * (plot_y2 - plot_y1));
      const int y_m3 = plot_y1 + (int)(((max_v - -3.0) / range) * (plot_y2 - plot_y1));

      const int y_zero_clamped = MathMax(plot_y1 + line_h / 2, MathMin(plot_y2 - line_h / 2, y_zero));
      const int y_p2_clamped = MathMax(plot_y1 + line_h / 2, MathMin(plot_y2 - line_h / 2, y_p2));
      const int y_m2_clamped = MathMax(plot_y1 + line_h / 2, MathMin(plot_y2 - line_h / 2, y_m2));
      const int y_p3_clamped = MathMax(plot_y1 + line_h / 2, MathMin(plot_y2 - line_h / 2, y_p3));
      const int y_m3_clamped = MathMax(plot_y1 + line_h / 2, MathMin(plot_y2 - line_h / 2, y_m3));

      const int label_w = 24;
      const int label_h = 14;
      const int label_x = plot_x1 + 2;
      m_lbl_p3.Move(label_x, y_p3_clamped - label_h / 2);
      m_lbl_p3.Size(label_w, label_h);
      m_lbl_p3.Visible(true);
      m_lbl_p2.Move(label_x, y_p2_clamped - label_h / 2);
      m_lbl_p2.Size(label_w, label_h);
      m_lbl_p2.Visible(true);
      m_lbl_zero.Move(label_x, y_zero_clamped - label_h / 2);
      m_lbl_zero.Size(label_w, label_h);
      m_lbl_zero.Visible(true);
      m_lbl_m2.Move(label_x, y_m2_clamped - label_h / 2);
      m_lbl_m2.Size(label_w, label_h);
      m_lbl_m2.Visible(true);
      m_lbl_m3.Move(label_x, y_m3_clamped - label_h / 2);
      m_lbl_m3.Size(label_w, label_h);
      m_lbl_m3.Visible(true);

      m_line_zero.Move(plot_x1, y_zero_clamped - line_h / 2);
      m_line_zero.Size(plot_x2 - plot_x1, line_h);
      m_line_zero.Visible(true);

      m_line_p2.Move(plot_x1, y_p2_clamped - line_h / 2);
      m_line_p2.Size(plot_x2 - plot_x1, line_h);
      m_line_p2.Visible(true);

      m_line_m2.Move(plot_x1, y_m2_clamped - line_h / 2);
      m_line_m2.Size(plot_x2 - plot_x1, line_h);
      m_line_m2.Visible(true);

      const int dotted_h = 2;
      const int dotted_gap = 10;
      int dotted_idx = 0;
      for(int x = plot_x1; x <= plot_x2 && dotted_idx < ArraySize(m_dots_p3); x += dotted_gap)
        {
         m_dots_p3[dotted_idx].Move(x, y_p3_clamped - dotted_h / 2);
         m_dots_p3[dotted_idx].Size(3, dotted_h);
         m_dots_p3[dotted_idx].Visible(true);
         dotted_idx++;
        }
      for(int i = dotted_idx; i < ArraySize(m_dots_p3); i++)
         m_dots_p3[i].Visible(false);

      dotted_idx = 0;
      for(int x = plot_x1; x <= plot_x2 && dotted_idx < ArraySize(m_dots_m3); x += dotted_gap)
        {
         m_dots_m3[dotted_idx].Move(x, y_m3_clamped - dotted_h / 2);
         m_dots_m3[dotted_idx].Size(3, dotted_h);
         m_dots_m3[dotted_idx].Visible(true);
         dotted_idx++;
        }
      for(int i = dotted_idx; i < ArraySize(m_dots_m3); i++)
         m_dots_m3[i].Visible(false);

      const int dot = 6;
      const int dots_total = MathMin(total, ArraySize(m_dots));
      int xs[];
      int ys[];
      ArrayResize(xs, dots_total);
      ArrayResize(ys, dots_total);

      for(int i = 0; i < dots_total; i++)
        {
         const int x = plot_x1 + (int)((double)i * (plot_x2 - plot_x1) / (double)(dots_total - 1));
         const double val = zvals[i];
         const double clamped_val = MathMax(-max_abs, MathMin(max_abs, val));
         int y = plot_y1 + (int)(((max_v - clamped_val) / range) * (plot_y2 - plot_y1));
         y = MathMax(plot_y1, MathMin(plot_y2, y));
         xs[i] = x;
         ys[i] = y;
         m_dots[i].Move(x - dot / 2, y - dot / 2);
         m_dots[i].Size(dot, dot);
         m_dots[i].Visible(true);
        }
      for(int i = dots_total; i < ArraySize(m_dots); i++)
         m_dots[i].Visible(false);

      int line_count = 0;
      const int line_size = 2;
      for(int i = 1; i < dots_total && line_count < ArraySize(m_line_dots); i++)
        {
         const int x1 = xs[i - 1];
         const int y1 = ys[i - 1];
         const int x2 = xs[i];
         const int y2 = ys[i];
         int dx = MathAbs(x2 - x1);
         int dy = MathAbs(y2 - y1);
         int steps = (dx > dy ? dx : dy);
         if(steps < 1)
            steps = 1;
         for(int s = 0; s <= steps && line_count < ArraySize(m_line_dots); s++)
           {
            const int x = x1 + (int)((double)(x2 - x1) * s / steps);
            const int y = y1 + (int)((double)(y2 - y1) * s / steps);
            m_line_dots[line_count].Move(x - line_size / 2, y - line_size / 2);
            m_line_dots[line_count].Size(line_size, line_size);
            m_line_dots[line_count].Visible(true);
            line_count++;
           }
        }
      for(int i = line_count; i < ArraySize(m_line_dots); i++)
         m_line_dots[i].Visible(false);

      const double last = zvals[total - 1];
      m_title.Text(title + " | last=" + DoubleToString(last, 2));
      ChartRedraw(0);
     }
  };

#endif
