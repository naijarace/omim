#include "testing/testing.hpp"

#include "search/query_saver.hpp"

#include "std/string.hpp"
#include "std/vector.hpp"

namespace
{
string const record1("test record1");
string const record2("sometext");
}

namespace search
{
UNIT_TEST(QuerySaverFogTest)
{
  QuerySaver saver;
  saver.Clear();
  saver.SaveNewQuery(record1);
  list<string> const & result = saver.GetTopQueries();
  TEST_EQUAL(result.size(), 1, ());
  TEST_EQUAL(result.front(), record1, ());
  saver.Clear();
}

UNIT_TEST(QuerySaverClearTest)
{
  QuerySaver saver;
  saver.Clear();
  saver.SaveNewQuery(record1);
  TEST_GREATER(saver.GetTopQueries().size(), 0, ());
  saver.Clear();
  TEST_EQUAL(saver.GetTopQueries().size(), 0, ());
}

UNIT_TEST(QuerySaverOrderingTest)
{
  QuerySaver saver;
  saver.Clear();
  saver.SaveNewQuery(record1);
  saver.SaveNewQuery(record2);
  {
    list<string> const & result = saver.GetTopQueries();
    TEST_EQUAL(result.size(), 2, ());
    TEST_EQUAL(result.back(), record1, ());
    TEST_EQUAL(result.front(), record2, ());
  }
  saver.SaveNewQuery(record1);
  {
    list<string> const & result = saver.GetTopQueries();
    TEST_EQUAL(result.size(), 2, ());
    TEST_EQUAL(result.front(), record1, ());
    TEST_EQUAL(result.back(), record2, ());
  }
  saver.Clear();
}

UNIT_TEST(QuerySaverSerializerTest)
{
  QuerySaver saver;
  saver.Clear();
  saver.SaveNewQuery(record1);
  saver.SaveNewQuery(record2);
  vector<char> data;
  saver.Serialize(data);
  TEST_GREATER(data.size(), 0, ());
  saver.Clear();
  TEST_EQUAL(saver.GetTopQueries().size(), 0, ());
  saver.Deserialize(string(data.begin(), data.end()));

  list<string> const & result = saver.GetTopQueries();
  TEST_EQUAL(result.size(), 2, ());
  TEST_EQUAL(result.back(), record1, ());
  TEST_EQUAL(result.front(), record2, ());
}

UNIT_TEST(QuerySaverPersistanceStore)
{
  {
    QuerySaver saver;
    saver.Clear();
    saver.SaveNewQuery(record1);
    saver.SaveNewQuery(record2);
  }
  {
    QuerySaver saver;
    list<string> const & result = saver.GetTopQueries();
    TEST_EQUAL(result.size(), 2, ());
    TEST_EQUAL(result.back(), record1, ());
    TEST_EQUAL(result.front(), record2, ());
    saver.Clear();
  }
}
}  // namespace search
