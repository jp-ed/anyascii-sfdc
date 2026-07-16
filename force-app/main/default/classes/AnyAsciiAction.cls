public with sharing class AnyAsciiAction {
    
    @InvocableMethod(
        label = 'Convert Unicode to ASCII'
        description='Replaces foreign characters with their American English equivalent.'
    )
    public static List<Response> execute(List<Request> reqs) {
        List<Response> rs = new List<Response>();
        for (Request req : reqs) {
            Map<String, List<Integer>> nonAsciiCodePointIndexMap = new Map<String, List<Integer>>();
            // Primarily for low surrogate pairs
            List<Integer> indxsToRemove = new List<Integer>(); 
            List<String> strParts = req.inputString.split('');
            for (Integer i = 0; i < strParts.size(); i++) {
                Integer cp = strParts[i].codePointAt(0);
                // High surrogate pair
                if (cp >= 55296 && cp <= 56319) {
                    cp = getSurrogatePairCodePoint(
                        strParts[i].codePointAt(0),
                        strParts[i+1].codePointAt(0)
                    );
                // Low surrogate pair
                } else if (cp >= 56320 && cp <= 57343) {
                    indxsToRemove.add(i);
                    continue;
                }
                // Already an ASCII chararacter
                if (cp <= 127) {
                    continue;
                } else {
                    String cpStr = cp.toString();
                    if (nonAsciiCodePointIndexMap.get(cpStr) == null) {
                        nonAsciiCodePointIndexMap.put(cpStr, new List<Integer>{i});
                    } else {    
                        List<Integer> indxs = nonAsciiCodePointIndexMap.get(cpStr);
                        indxs.add(i);
                        nonAsciiCodePointIndexMap.put(cpStr, indxs);
                    }
                }
            }
            if (nonAsciiCodePointIndexMap.keySet().size() > 0) {
                System.debug('Querying for code points: ' + nonAsciiCodePointIndexMap.keySet());
                List<AnyAsciiMapping__c> mps = [SELECT Id, CodePoint__c,
                                                    OutputValue__c, IsBlankSpace__c
                                                FROM AnyAsciiMapping__c
                                                WHERE CodePoint__c IN :nonAsciiCodePointIndexMap.keySet()
                                                    AND IsActive__c = true
                                                WITH USER_MODE];
    
                for (AnyAsciiMapping__c mp : mps) {
                    List<Integer> indxs = nonAsciiCodePointIndexMap.get(mp.CodePoint__c);
                    for (Integer j = 0; j < indxs.size(); j++) {
                        Integer cp = Integer.valueOf(mp.CodePoint__c);
                        // Replacement can be a space, ASCII character, or empty string
                        strParts[indxs[j]] = mp.IsBlankSpace__c ? ' ' : (mp.OutputValue__c ?? '');
                    }
                    for (Integer k = 0; k < indxsToRemove.size(); k++) {
                        // Replace low surrogate with empty string
                        strParts[indxsToRemove[k]] = '';
                    }
                }
            }
            String newStr = String.join(strParts, '');
            Response r = new Response();
            Pattern asciiPattern = Pattern.compile('^[ -~]*$');
            Matcher asciiMatcher = asciiPattern.matcher(newStr);
            Assert.isTrue(asciiMatcher.matches(), 'Output string does not match ASCII regular expression: ' + newStr);
            r.outputString = newStr.trim();
            rs.add(r);
        }
        return rs;
    }
    
    private static Integer getSurrogatePairCodePoint(Integer high, Integer low) {
        return ((high - 55296) << 10) + (low - 56320) + 65536;
    }
    
    public class Request {
        @InvocableVariable(label='Unicode Input String' required=true)
        public String inputString;
    }
    
    public class Response {
        @InvocableVariable(label='ASCII Output String')
        public String outputString;
    }
}
