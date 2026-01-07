#property strict
#ifndef __LONGSHORTMETRICS_MQH__
#define __LONGSHORTMETRICS_MQH__

// Basic metrics helpers for LongShort pairs.

double Clamp01(const double value)
{
   if(value < 0.0)
      return(0.0);
   if(value > 1.0)
      return(1.0);
   return(value);
}

// Calculates log-returns from price series for a given window (latest window).
bool CalcLogReturns(const double &prices[], const int prices_count, const int window, double &returns[])
{
   if(window < 1 || prices_count < window + 1)
      return(false);
   ArrayResize(returns, window);
   for(int i = 0; i < window; i++)
     {
      const double p0 = prices[i];
      const double p1 = prices[i + 1];
      if(p0 <= 0.0 || p1 <= 0.0)
         returns[i] = 0.0;
      else
         returns[i] = MathLog(p0 / p1);
     }
   return(true);
}

// Pearson correlation for two vectors.
bool CorrPearson(const double &a[], const double &b[], const int n, double &corr)
{
   if(n < 2)
      return(false);
   double mean_a = 0.0;
   double mean_b = 0.0;
   for(int i = 0; i < n; i++)
     {
      mean_a += a[i];
      mean_b += b[i];
     }
   mean_a /= n;
   mean_b /= n;

   double num = 0.0;
   double den_a = 0.0;
   double den_b = 0.0;
   for(int i = 0; i < n; i++)
     {
      const double da = a[i] - mean_a;
      const double db = b[i] - mean_b;
      num += da * db;
      den_a += da * da;
      den_b += db * db;
     }
   if(den_a <= 0.0 || den_b <= 0.0)
      return(false);
   corr = num / MathSqrt(den_a * den_b);
   return(true);
}

// Pearson correlation of log-returns from two price series.
bool CorrPearsonReturnsFromPrices(const double &prices_a[], const double &prices_b[], const int prices_count, const int window, double &corr)
{
   double ra[];
   double rb[];
   if(!CalcLogReturns(prices_a, prices_count, window, ra))
      return(false);
   if(!CalcLogReturns(prices_b, prices_count, window, rb))
      return(false);
   return(CorrPearson(ra, rb, window, corr));
}

// Correlation score in [0..1] based on configured minimum.
double ScoreCorr(const double corr, const double corr_min)
{
   if(corr_min >= 1.0)
      return(0.0);
   return(Clamp01((corr - corr_min) / (1.0 - corr_min)));
}

double ErfApprox(const double x)
{
   // Abramowitz and Stegun 7.1.26 approximation
   const double a1 = 0.254829592;
   const double a2 = -0.284496736;
   const double a3 = 1.421413741;
   const double a4 = -1.453152027;
   const double a5 = 1.061405429;
   const double p = 0.3275911;
   const double sign = (x < 0.0 ? -1.0 : 1.0);
   const double ax = MathAbs(x);
   const double t = 1.0 / (1.0 + p * ax);
   const double y = 1.0 - (((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t * MathExp(-ax * ax));
   return(sign * y);
}

double NormalCdf(const double x)
{
   return(0.5 * (1.0 + ErfApprox(x / MathSqrt(2.0))));
}

// Stubs for next metrics.
bool CalcBetaOLS(const double &prices_a[], const double &prices_b[], const int prices_count, const int window, double &beta)
{
   double ra[];
   double rb[];
   if(!CalcLogReturns(prices_a, prices_count, window, ra))
      return(false);
   if(!CalcLogReturns(prices_b, prices_count, window, rb))
      return(false);

   double mean_a = 0.0;
   double mean_b = 0.0;
   for(int i = 0; i < window; i++)
     {
      mean_a += ra[i];
      mean_b += rb[i];
     }
   mean_a /= window;
   mean_b /= window;

   double cov = 0.0;
   double var_b = 0.0;
   for(int i = 0; i < window; i++)
     {
      const double da = ra[i] - mean_a;
      const double db = rb[i] - mean_b;
      cov += da * db;
      var_b += db * db;
     }
   if(var_b <= 0.0)
      return(false);
   beta = cov / var_b;
   return(true);
}

bool CalcZScore(const double &spread[], const int spread_count, const int window, double &zscore)
{
   if(window < 2 || spread_count < window)
      return(false);
   double mean = 0.0;
   for(int i = 0; i < window; i++)
      mean += spread[i];
   mean /= window;

   double var = 0.0;
   for(int i = 0; i < window; i++)
     {
      const double d = spread[i] - mean;
      var += d * d;
     }
   var /= window;
   if(var <= 0.0)
      return(false);
   const double std = MathSqrt(var);
   zscore = (spread[0] - mean) / std;
   return(true);
}

bool CalcHalfLife(const double &spread[], const int spread_count, double &half_life)
{
   if(spread_count < 2)
      return(false);

   double mean = 0.0;
   for(int i = 0; i < spread_count; i++)
      mean += spread[i];
   mean /= spread_count;

   double num = 0.0;
   double den = 0.0;
   for(int i = 0; i < spread_count - 1; i++)
     {
      const double x = spread[i + 1] - mean;
      const double y = (spread[i] - spread[i + 1]);
      num += x * y;
      den += x * x;
     }
   if(den <= 0.0)
      return(false);
   const double b = num / den;
   if(b >= 0.0)
      return(false);
   half_life = -MathLog(2.0) / b;
   return(true);
}

bool CalcADF(const double &spread[], const int spread_count, double &adf_pvalue)
{
   if(spread_count < 3)
      return(false);

   const int n = spread_count - 1;
   double sum_x = 0.0;
   double sum_y = 0.0;
   for(int i = 0; i < n; i++)
     {
      const double x = spread[i + 1];
      const double y = spread[i] - spread[i + 1];
      sum_x += x;
      sum_y += y;
     }
   const double mean_x = sum_x / n;
   const double mean_y = sum_y / n;

   double sum_xx = 0.0;
   double sum_xy = 0.0;
   for(int i = 0; i < n; i++)
     {
      const double x = spread[i + 1];
      const double y = spread[i] - spread[i + 1];
      const double dx = x - mean_x;
      const double dy = y - mean_y;
      sum_xx += dx * dx;
      sum_xy += dx * dy;
     }
   if(sum_xx <= 0.0)
      return(false);

   const double b = sum_xy / sum_xx;
   const double a = mean_y - b * mean_x;

   double rss = 0.0;
   for(int i = 0; i < n; i++)
     {
      const double x = spread[i + 1];
      const double y = spread[i] - spread[i + 1];
      const double y_hat = a + b * x;
      const double e = y - y_hat;
      rss += e * e;
     }
   if(n <= 2)
      return(false);
   const double s2 = rss / (n - 2);
   if(s2 <= 0.0)
      return(false);
   const double se_b = MathSqrt(s2 / sum_xx);
   if(se_b <= 0.0)
      return(false);

   const double t_stat = b / se_b;
   adf_pvalue = NormalCdf(t_stat);
   return(true);
}

#endif // __LONGSHORTMETRICS_MQH__
