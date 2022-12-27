import { LightningElement, wire, track, api } from 'lwc';
import getToken from '@salesforce/apex/CaseController.getToken';
import estadoZonasPost from '@salesforce/apex/CaseController.estadoZonasPost';

export default class CheckZoneStatus extends LightningElement {
    @api recordId
    @track estado
    @track demora
    checkStatus(event){
        estadoZonasPost({'recordId': this.recordId})
        .then(response => {
            const res = JSON.parse(response);
            this.estado = res.estado;
            this.demora = res.demora;
            console.log(res);
            console.log('Var 1', this.estado);
            console.log('Var 2', this.demora);
        })
    }
}