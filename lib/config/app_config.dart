class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yjbsbkhvltrdiwhpyszb.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlqYnNia2h2bHRyZGl3aHB5c3piIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcyMDQwNzAsImV4cCI6MjA2Mjc4MDA3MH0.MLDCgk2QzCHAZDO-w1TD6AYalEJs2n4qfrrUBjS0R7E',
  );

  static const String cohereApiKey = String.fromEnvironment(
    'COHERE_API_KEY',
    defaultValue: 'b1QpkHTSkhKucB9s4uVgX4dO8wr839VxnOnCtUFh',
  );
}
