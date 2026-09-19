@IsTest
private class GetAccountsByFilterTest {

    @TestSetup
    static void makeData() {
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Alpha Corp',   Rating = 'Hot',  Type = 'Customer',  BillingCountry = 'United States'),
            new Account(Name = 'Beta LLC',     Rating = 'Warm', Type = 'Partner',   BillingCountry = 'United Kingdom'),
            new Account(Name = 'Gamma Inc',    Rating = 'Hot',  Type = 'Customer',  BillingCountry = 'United States'),
            new Account(Name = 'Delta Ltd',    Rating = 'Cold', Type = 'Prospect',  BillingCountry = 'Germany'),
            new Account(Name = 'Alpha Venture',Rating = 'Hot',  Type = 'Customer',  BillingCountry = 'United States')
        };
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        // Alpha Corp gets 3 contacts, Gamma Inc gets 1, Alpha Venture gets 2
        for (Integer i = 0; i < 3; i++) {
            contacts.add(new Contact(LastName = 'AC' + i, AccountId = accounts[0].Id));
        }
        contacts.add(new Contact(LastName = 'GI0', AccountId = accounts[2].Id));
        for (Integer i = 0; i < 2; i++) {
            contacts.add(new Contact(LastName = 'AV' + i, AccountId = accounts[4].Id));
        }
        insert contacts;
    }

    @IsTest
    static void testFilterByRating() {
        GetAccountsByFilter.Request req = new GetAccountsByFilter.Request();
        req.rating = 'Hot';

        Test.startTest();
        List<GetAccountsByFilter.Response> responses = GetAccountsByFilter.getAccounts(
            new List<GetAccountsByFilter.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Expected one response');
        GetAccountsByFilter.Response res = responses[0];
        System.assertNotEquals(null, res.accounts, 'Accounts list should not be null');
        System.assertEquals(3, res.accounts.size(), 'Expected 3 Hot accounts');
        System.assertEquals(null, res.errorMessage, 'No error expected');
        // First row should have most contacts (Alpha Corp = 3)
        System.assertEquals(3, res.accounts[0].contactCount, 'Top account should have 3 contacts');
    }

    @IsTest
    static void testFilterByCountry() {
        GetAccountsByFilter.Request req = new GetAccountsByFilter.Request();
        req.country = 'United States';

        Test.startTest();
        List<GetAccountsByFilter.Response> responses = GetAccountsByFilter.getAccounts(
            new List<GetAccountsByFilter.Request>{ req }
        );
        Test.stopTest();

        GetAccountsByFilter.Response res = responses[0];
        System.assertEquals(3, res.accounts.size(), 'Expected 3 US accounts');
        // Verify descending order by contact count
        for (Integer i = 0; i < res.accounts.size() - 1; i++) {
            System.assert(
                res.accounts[i].contactCount >= res.accounts[i + 1].contactCount,
                'Results should be sorted descending by contact count'
            );
        }
    }

    @IsTest
    static void testFilterByAccountName() {
        GetAccountsByFilter.Request req = new GetAccountsByFilter.Request();
        req.accountName = 'Alpha';

        Test.startTest();
        List<GetAccountsByFilter.Response> responses = GetAccountsByFilter.getAccounts(
            new List<GetAccountsByFilter.Request>{ req }
        );
        Test.stopTest();

        GetAccountsByFilter.Response res = responses[0];
        System.assertEquals(2, res.accounts.size(), 'Expected 2 Alpha accounts');
    }

    @IsTest
    static void testFilterByType() {
        GetAccountsByFilter.Request req = new GetAccountsByFilter.Request();
        req.type = 'Partner';

        Test.startTest();
        List<GetAccountsByFilter.Response> responses = GetAccountsByFilter.getAccounts(
            new List<GetAccountsByFilter.Request>{ req }
        );
        Test.stopTest();

        GetAccountsByFilter.Response res = responses[0];
        System.assertEquals(1, res.accounts.size(), 'Expected 1 Partner account');
        System.assertEquals('Beta LLC', res.accounts[0].accountName);
    }

    @IsTest
    static void testCombinedFilters() {
        GetAccountsByFilter.Request req = new GetAccountsByFilter.Request();
        req.rating  = 'Hot';
        req.type    = 'Customer';
        req.country = 'United States';

        Test.startTest();
        List<GetAccountsByFilter.Response> responses = GetAccountsByFilter.getAccounts(
            new List<GetAccountsByFilter.Request>{ req }
        );
        Test.stopTest();

        GetAccountsByFilter.Response res = responses[0];
        System.assertEquals(null, res.errorMessage);
        System.assert(res.accounts.size() <= 10, 'Result capped at 10');
    }

    @IsTest
    static void testNoFiltersReturnsError() {
        GetAccountsByFilter.Request req = new GetAccountsByFilter.Request();

        Test.startTest();
        List<GetAccountsByFilter.Response> responses = GetAccountsByFilter.getAccounts(
            new List<GetAccountsByFilter.Request>{ req }
        );
        Test.stopTest();

        GetAccountsByFilter.Response res = responses[0];
        System.assertNotEquals(null, res.errorMessage, 'Expected an error message');
        System.assertEquals(0, res.accounts.size(), 'No accounts returned on error');
    }

    @IsTest
    static void testResponseFieldsPopulated() {
        GetAccountsByFilter.Request req = new GetAccountsByFilter.Request();
        req.rating = 'Hot';

        Test.startTest();
        List<GetAccountsByFilter.Response> responses = GetAccountsByFilter.getAccounts(
            new List<GetAccountsByFilter.Request>{ req }
        );
        Test.stopTest();

        GetAccountsByFilter.AccountRow row = responses[0].accounts[0];
        System.assertNotEquals(null, row.accountId,   'Id required');
        System.assertNotEquals(null, row.accountName, 'Name required');
        System.assertNotEquals(null, row.rating,      'Rating required');
        System.assertNotEquals(null, row.contactCount,'Contact count required');
    }
}
