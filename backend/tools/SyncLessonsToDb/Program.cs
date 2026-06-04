using Npgsql;

if (args.Length < 2)
{
    Console.Error.WriteLine("Usage: SyncLessonsToDb <connectionString> <sqlFilePath>");
    return 1;
}

var connectionString = args[0];
var sqlPath = args[1];
if (!File.Exists(sqlPath))
{
    Console.Error.WriteLine($"SQL file not found: {sqlPath}");
    return 1;
}

var sql = await File.ReadAllTextAsync(sqlPath);

await using var conn = new NpgsqlConnection(connectionString);
await conn.OpenAsync();

await using var tx = await conn.BeginTransactionAsync();
try
{
    await using (var cmd = new NpgsqlCommand(sql, conn, tx))
    {
        cmd.CommandTimeout = 120;
        await cmd.ExecuteNonQueryAsync();
    }

    await tx.CommitAsync();
    Console.WriteLine("Done syncing lessons.");
}
catch (Exception ex)
{
    try { await tx.RollbackAsync(); } catch { /* already rolled back */ }
    Console.Error.WriteLine(ex.ToString());
    return 1;
}

const string verifySql = """
    SELECT l.id, l.title, l.is_published, LENGTH(COALESCE(l.content, '')) AS content_len,
           (SELECT COUNT(*) FROM vocabulary_items v WHERE v.lesson_id = l.id) AS vocab,
           (SELECT COUNT(*) FROM kanji_items k WHERE k.lesson_id = l.id) AS kanji
    FROM lessons l
    ORDER BY l.id;
    """;

await using var verify = new NpgsqlCommand(verifySql, conn);
await using var reader = await verify.ExecuteReaderAsync();
Console.WriteLine();
Console.WriteLine("id | title | published | content_len | vocab | kanji");
Console.WriteLine("---|-------|-----------|-------------|-------|------");
while (await reader.ReadAsync())
{
    var pub = reader.GetBoolean(2) ? "yes" : "no";
    Console.WriteLine($"{reader.GetInt32(0)} | {reader.GetString(1)} | {pub} | {reader.GetInt64(3)} | {reader.GetInt64(4)} | {reader.GetInt64(5)}");
}

return 0;
