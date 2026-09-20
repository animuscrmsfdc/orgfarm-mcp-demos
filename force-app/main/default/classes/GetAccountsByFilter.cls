global with sharing class GetAccountsByFilter {

    global class Request {
        @InvocableVariable(label='Rating' description='Account Rating (e.g. Hot, Warm, Cold)')
        public String rating;
        @InvocableVariable(label='Type' description='Account Type (e.g. Customer, Partner, Prospect)')
        public String type;
        @InvocableVariable(label='Country' description='Billing Country')
        public String country;
        @InvocableVariable(label='Account Name' description='Partial or full Account Name (wildcard search)')
        public String accountName;
        global Request() {}
    }

    global class AccountRow {
        @InvocableVariable(label='Account Id')
        public Id accountId;
        @InvocableVariable(label='Account Name')
        public String accountName;
        @InvocableVariable(label='Rating')
        public String rating;
        @InvocableVariable(label='Type')
        public String type;
        @InvocableVariable(label='Country')
        public String country;
        @InvocableVariable(label='Contact Count')
        public Integer contactCount;
        global AccountRow() {}
    }

    global class Response {
        @InvocableVariable(label='Accounts JSON' description='JSON array of matching account rows; parse with JSON.deserialize or any MCP client')
        public String accountsJson;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        global Response() {}
    }

    @InvocableMethod(
        label='Get Accounts By Filter'
        description='Returns up to 10 accounts matching Rating, Type, Billing Country, and Account Name filters, sorted by Contact count descending.'
    )
    global static List<Response> getAccounts(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();

            if (String.isBlank(req.rating) && String.isBlank(req.type)
                    && String.isBlank(req.country) && String.isBlank(req.accountName)) {
                res.errorMessage = 'Please provide at least one filter: Rating, Type, Country, or Account Name.';
                responses.add(res);
                continue;
            }

            String baseQuery = 'SELECT Id, Name, Rating, Type, BillingCountry, '
                + '(SELECT Id FROM Contacts) '
                + 'FROM Account WHERE Id != null';

            if (String.isNotBlank(req.rating)) {
                baseQuery += ' AND Rating = :rating';
            }
            if (String.isNotBlank(req.type)) {
                baseQuery += ' AND Type = :type';
            }
            if (String.isNotBlank(req.country)) {
                baseQuery += ' AND BillingCountry = :country';
            }
            if (String.isNotBlank(req.accountName)) {
                baseQuery += ' AND Name LIKE :nameLike';
            }

            String rating    = String.isNotBlank(req.rating)      ? req.rating.trim()      : null;
            String type      = String.isNotBlank(req.type)         ? req.type.trim()         : null;
            String country   = String.isNotBlank(req.country)      ? req.country.trim()      : null;
            String nameLike  = String.isNotBlank(req.accountName)  ? '%' + req.accountName.trim() + '%' : null;

            List<Account> accounts;
            try {
                // Dynamic SOQL with WITH USER_MODE enforces FLS and sharing
                accounts = Database.queryWithBinds(
                    baseQuery + ' WITH USER_MODE',
                    new Map<String, Object>{
                        'rating'   => rating,
                        'type'     => type,
                        'country'  => country,
                        'nameLike' => nameLike
                    },
                    AccessLevel.USER_MODE
                );
            } catch (Exception e) {
                res.errorMessage = 'Query error: ' + e.getMessage();
                responses.add(res);
                continue;
            }

            List<AccountRow> rows = new List<AccountRow>();
            for (Account a : accounts) {
                AccountRow row    = new AccountRow();
                row.accountId    = a.Id;
                row.accountName  = a.Name;
                row.rating       = a.Rating;
                row.type         = a.Type;
                row.country      = a.BillingCountry;
                row.contactCount = a.Contacts.size();
                rows.add(row);
            }

            rows.sort(new ContactCountComparator());

            Integer limit10 = Math.min(rows.size(), 10);
            res.accountsJson = JSON.serialize(rows.subList(0, limit10));

            responses.add(res);
        }

        return responses;
    }

    private class ContactCountComparator implements Comparator<AccountRow> {
        public Integer compare(AccountRow a, AccountRow b) {
            return b.contactCount - a.contactCount;
        }
    }
}
