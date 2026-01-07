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
   // TODO: implement half-life on spread.
   half_life = 0.0;
   return(false);
}

bool CalcADF(const double &spread[], const int spread_count, double &adf_pvalue)
{
   // TODO: implement ADF test.
   adf_pvalue = 0.0;
   return(false);
}

#endif // __LONGSHORTMETRICS_MQH__
