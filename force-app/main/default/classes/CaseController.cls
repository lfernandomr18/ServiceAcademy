public with sharing class CaseController {
    
    public static List <EntitlementContact> getEntlContacts(Set<Id> contactIds){
        return [Select e.EntitlementId,e.ContactId,e.Entitlement.AssetId
        From EntitlementContact e
        Where e.ContactId in :contactIds
        And e.Entitlement.EndDate >= Today
        And e.Entitlement.StartDate <= Today];
    } 
    public static List <Entitlement> getEntl(Set<Id> acctIds){
        return [Select e.StartDate, e.Id, e.EndDate,
        e.AccountId, e.AssetId
        From Entitlement e
        Where e.AccountId in :acctIds And e.EndDate >= Today
        And e.StartDate <= Today];
    }
    public static List<String> addidsExternos(List<case> triggernew){
        List<String> idsExternos = new  List<String>();
        for(case c : triggernew){
            idsExternos.add(c.ID_externo__c);  
        }
        return idsExternos;

    }
    public static List<Account> getAccsByIdExterno(List<String> idsExternos){
        return [SELECT Id, ID_externo__c FROM Account where ID_externo__c  IN:idsExternos AND ID_externo__c !=''];
    }

    public static Map<String,Account>  assignAccToMap(List<Account> accsByIdExterno,List<case> triggernew){
        Map<String,Account> accMap = new Map<String,Account>();
        for(Account acc :accsByIdExterno ){
            for(case c : triggernew){
               if(c.ID_externo__c == acc.ID_externo__c){
                accMap.put(c.ID_externo__c, acc);
               }
            }
        }
        return accMap;
    }

    public static void beforeInsertHandler(List<Case> triggernew,Set<Id> contactIds,Set<Id> acctIds,Map<String,Account> accMap,Boolean existeError){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Boolean emailfromweb=true;
        
        for(Case c : triggernew) {
            if( c.AccountId !=null && c.ContactId !=null ){
                contactIds.add(c.ContactId);
                acctIds.add(c.AccountId);
            }
            else if(c.AccountId !=null && c.ContactId ==null){
                contactIds.add(c.ContactId);
                acctIds.add(c.AccountId);
            }
            else{
                contactIds.add(c.ContactId);
                if(accMap.containsKey(c.ID_externo__c)){
                    c.AccountId=accMap.get(c.ID_externo__c).Id;
                    acctIds.add(accMap.get(c.ID_externo__c).Id);
                    //este record Type pertenece a Reclamos
                    if(c.RecordTypeId =='0128c000001Q3aiAAC'){
                        c.Status='New';
                        c.Priority='Medium';
                        c.OwnerId='00G8c000007cJJ1EAM';
                    }
                    //Consultas
                    else{  
                        c.Status='New';
                        c.Priority='Low';
                        c.OwnerId='00G8c000007cJIwEAM';
                    }
                }
                else{
                    acctIds.add(c.AccountId);
                }  
            }
            if(existeError==true){
                
               if(c.emailFromWeb__c!= null) {
                c.Status='Closed'; 
                c.Reason='No Existe ID';
                c.OwnerId='0058c00000CUzj7AAD';
                mails.add(generateMail(c)); 
               }
               else{
                emailfromweb=false;
               }
                     
            }         
        }
        if(existeError==true){
            if(emailfromweb== true) {
            Messaging.sendEmail(mails);
            }
        }
        
        List <EntitlementContact> entlContacts = getEntlContacts(contactIds);
        if(entlContacts.isEmpty()==false){
            for(Case c : triggernew){
                if(c.EntitlementId == null && c.ContactId != null){
                    for(EntitlementContact ec:entlContacts){
                        if(ec.ContactId==c.ContactId){
                            c.EntitlementId = ec.EntitlementId;
                            if(c.AssetId==null && ec.Entitlement.AssetId!=null)
                                c.AssetId=ec.Entitlement.AssetId;
                            break;
                        }
                    }
                }
            }
        } else{
            List <Entitlement> entls = getEntl(acctIds);
            if(entls.isEmpty()==false){
                for(Case c : triggernew){
                    if(c.EntitlementId == null && c.AccountId != null){
                        for(Entitlement e:entls){
                            if(e.AccountId==c.AccountId){
                                c.EntitlementId = e.Id;
                                if(c.AssetId==null && e.AssetId!=null)
                                    c.AssetId=e.AssetId;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    public static Messaging.SingleEmailMessage generateMail(case c){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>();
        sendTo.add(c.emailFromWeb__c);
        mail.setToAddresses(sendTo);
        mail.setSubject('No se ha creado CASO ');
        String body = 'Estimado Usuario,'; 
        body += 'No se ha podido registrar su caso debido a que el ID: '+c.ID_externo__c+' no se encuentra en nuestra Base de datos, ';
        body += 'Ingresar un Id correcto ';
        body += 'Para más detalle consulte con el Administrador ';
        
        mail.setHtmlBody(body);

        return mail;
    }
    public static void beforeUpdateHandler(List<Case> triggernew,Set<Id> contactIds,Set<Id> acctIds){
        for(Case c : triggernew) {
            contactIds.add(c.ContactId);
            acctIds.add(c.AccountId);
        }
        List <EntitlementContact> entlContacts = CaseController.getEntlContacts(contactIds);

        if(entlContacts.isEmpty()==false){
            for(Case c : triggernew){
                if(c.EntitlementId == null && c.ContactId != null){
                    for(EntitlementContact ec:entlContacts){
                        if(ec.ContactId==c.ContactId){
                            c.EntitlementId = ec.EntitlementId;
                            if(c.AssetId==null && ec.Entitlement.AssetId!=null)
                                c.AssetId=ec.Entitlement.AssetId;
                            break;
                        }
                    }
                }
            }
        } else{
            List <Entitlement> entls = CaseController.getEntl(acctIds);
            if(entls.isEmpty()==false){
                for(Case c : triggernew){
                    if(c.EntitlementId == null && c.AccountId != null){
                        for(Entitlement e:entls){
                            if(e.AccountId==c.AccountId){
                                c.EntitlementId = e.Id;
                                if(c.AssetId==null && e.AssetId!=null)
                                    c.AssetId=e.AssetId;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    public static void createContactfromWeb(List<Case> triggernew){
        List<Contact> contactToInsert = new List<Contact>();
        List<String> emailContactToQuery = new List<String>();
        Map<String,Contact> ContactMap= new Map<String,Contact>();
        for(Case c : triggernew){
            if(c.emailFromWeb__c != null){
                emailContactToQuery.add(c.emailFromWeb__c);
            }
        }
        List<Contact> ContactQueryResult = [SELECT Id, Email FROM Contact WHERE Email IN:emailContactToQuery];
        if(ContactQueryResult.isEmpty()){
            for(Case c: triggernew){
                if(c.emailFromWeb__c != null){
                    for(String cont :emailContactToQuery ){
                        if(c.emailFromWeb__c == cont){
                            if(!ContactMap.containsKey(c.emailFromWeb__c)){
                                Contact cont1 = new Contact(LastName='CTWeb'+c.emailFromWeb__c,Salutation='Mr.',Email=c.emailFromWeb__c,IdExternoContacto__c='CTWeb');
                                ContactMap.put(c.emailFromWeb__c, cont1);
                            }
                        }
                    }
                }
            }
        }
        for(String Key :ContactMap.keySet()){
            contactToInsert.add(ContactMap.get(Key));
        }        
        try{
            Database.SaveResult[] srList = Database.insert(contactToInsert, false);
            System.debug('SRRESULT'+srList);
        }catch(DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());
        }
    }
    public class tokenAPI{
        public String token; 
    }
    public class estadoZonaAPI{
        public String estado;
        public String demora;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getToken(){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://servermockexcercise.herokuapp.com/token');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer 00D8c000009N9va!AQwAQN59LPCvo7fKGP8wecfLE6WNVt0wQEnN8V959Vs20M7CUhuDhtkANUyYO2Xstbsor1RiZUJKam0QknT4yAAX_QFOn8dY');
        req.setHeader('Content-Type','application/json');
        String credentials = '{"user":"TEST","pass":"TEST"}';
        req.setBody(credentials);
        Http http = new Http();
        HttpResponse res = http.send(req);
        tokenAPI t = (tokenAPI)JSON.deserializeStrict(res.getBody(),tokenAPI.class);
        String token =t.token;
        return token; 
    }

    @AuraEnabled(cacheable=true)
    public static String estadoZonasPost(String recordId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://servermockexcercise.herokuapp.com/estadozona');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer '+getToken());
        req.setHeader('Content-Type','application/json');
        System.debug('Este es el Id que me está llegando: '+ recordId);
        String zona ='{"zona":"'+getZone(recordId)+'"}';
        System.debug(zona);
        req.setBody(zona);
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('RESPUESTA SERVICIO'+res.getBody());

        return res.getBody();
    }

    private static String getZone(String recordId){
        String accountId = '';
        String zona = '';
        List<Case> casos = [SELECT AccountId FROM Case WHERE Id = :recordId LIMIT 1];
        for(Case c : casos){
            accountId = c.AccountId;
        }
        List<Account> cuentas = [SELECT Zona__c FROM Account WHERE Id =  :accountId LIMIT 1];
        for(Account a : cuentas){
            zona = a.Zona__c;
        }
        System.debug(zona);
        return zona;
    }
   
}