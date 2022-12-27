trigger AddEntitlement on Case (before insert, before update) {
    Set<Id> contactIds = new Set<Id>();
    Set<Id> acctIds = new Set<Id>();
    Boolean existeError=false;
    Map<String,Account> accMap = new Map<String,Account>();
    switch on Trigger.operationType {
       
        when BEFORE_INSERT{
            List<String> idsExternos =CaseController.addidsExternos(Trigger.new); 
            if(!idsExternos.isEmpty()){
                List<Account> accsByIdExterno = CaseController.getAccsByIdExterno(idsExternos);
                System.debug(accsByIdExterno);
                if(accsByIdExterno.isEmpty()){
                    existeError=true;             
                }
                else{
                   accMap=CaseController.assignAccToMap(accsByIdExterno, Trigger.new).deepClone();
                }
            }
            system.debug(existeError);
            system.debug(accMap);
            CaseController.createContactfromWeb(Trigger.new);
            CaseController.beforeInsertHandler(Trigger.new, contactIds, acctIds, accMap, existeError);
        }
        when BEFORE_UPDATE{
           CaseController.beforeUpdateHandler(Trigger.new, contactIds, acctIds);    
        }

    }  
}