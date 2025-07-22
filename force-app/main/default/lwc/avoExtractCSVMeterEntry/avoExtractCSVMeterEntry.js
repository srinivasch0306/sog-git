import { LightningElement, api, wire, track} from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import extractCSV from '@salesforce/apex/AvoExtractCSVControllerMeterEntry.extractCSV';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AvoExtractCSVMeterEntry extends LightningElement {
    @api recordId;
    @api isOptionsNotEmpty = false;
    @api isLoading = false;
    @api isErrorCreatingReviews = false;
    @track options;
    @track showCreateButton = false;
    value = [];
    @track errorMessage = '';
    @track showError = false;
    @track entriesCreated = false;
    @track showExtractButton = true;

    // @wire (getAllowedReviewTypes,{recordId:'$recordId'}) getReviewTypes({data,error}){
    //     if (data) {
    //         console.log('data:'+ data);
    //         this.options = data.map( (obj)=> { return {label: obj.Name, value: obj.Id}});
    //         this.isOptionsNotEmpty = this.options.length > 0 ? true : false;
    //     } else if (error) {
    //         console.log(error);
    //     }
    // }

    // return a concatenated string representing the selected checkbox values
    // get selectedValues() {
    //     return this.value.join(',');
    // }

    // when a checkbox is checked
    // handleChange(e) {
    //     console.log('e:'+ e);
    //     this.value = e.detail.value;
    //     this.showCreateButton = this.value.length > 0? true: false; 
    // }

    handleSubmit() {
        extractCSV({recordId:this.recordId})
            .then((result) => {
                console.log('CSV Extracted');
                this.showExtractButton = false;
                this.entriesCreated = true;
            })
            .catch((error) => {
                console.log(error.body.message);
                this.errorMessage = error.body.message;
                this.showError = true;
                this.showExtractButton = false;
                // this.dispatchEvent(new CloseActionScreenEvent());
            })
    }
    handleFinish() {
        this.dispatchEvent(new CloseActionScreenEvent());
        getRecordNotifyChange([{recordId: this.recordId}]);
    }
    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}