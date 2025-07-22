import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadFile from '@salesforce/apex/AVOGISmapController.uploadFile';

export default class FileUploaderCompLwc extends LightningElement {
    fileData = {}; 
    fileName = ''; 
    FileContent = '';
    
    @track isUploading = false;
    @track uploadProgress = 0;
    @track serverResponse = ''; // Holds the Apex response

    handleFileChange(event) {
        const file = event.target.files[0];

        if (file) {
            // Validate file type
            if (!file.name.toLowerCase().endsWith('.csv')) {
                this.fileName = ''; 
                this.fileData = {}; 
                this.showToast('Error', 'Invalid file format! Please upload a .csv file.', 'error');
                return;
            }

            const reader = new FileReader();
            reader.readAsDataURL(file);
            reader.onload = () => {
                let base64 = reader.result.replace(/^data:(.*;base64,)?/, ''); 
                this.fileData = {
                    fileName: file.name,
                    base64Data: base64
                };
                this.fileName = file.name;
                this.FileContent = base64;
            };
        }
    }

    async handleUpload() {
        if (!this.fileData.base64Data) {
            this.showToast('Error', 'Please select a file first.', 'error');
            return;
        }

        this.isUploading = true;
        this.uploadProgress = 10; // Start Progress

        try {
            await this.simulateProgress(); // Simulate progress
            const result = await uploadFile({ 
                base64: this.fileData.base64Data
            });

            this.serverResponse = result; // Store the Apex response
            this.uploadProgress = 100; // Complete Progress

            setTimeout(() => {
                this.isUploading = false;
                this.uploadProgress = 0;

                if (this.isSuccessResponse(result)) {
                    this.showToast('Success', result, 'success');
                } else {
                    this.showToast('Error', result, 'error');
                }
            }, 1000);
        } catch (error) {
            console.error('Error uploading file:', error);
            this.serverResponse = 'Error: ' + (error.body ? error.body.message : 'Unknown error');
            this.isUploading = false;
            this.uploadProgress = 0;
            this.showToast('Error', 'File upload failed due to an error.', 'error');
        }
    }

    simulateProgress() {
        return new Promise((resolve) => {
            let progress = 20;
            const interval = setInterval(() => {
                progress += 20;
                if (progress >= 80) {
                    clearInterval(interval);
                    resolve();
                }
                this.uploadProgress = progress;
            }, 500);
        });
    }

    handleClear() {
        this.fileName = '';
        this.fileData = {}; 
        this.serverResponse = ''; // Clear server response

        const fileInput = this.template.querySelector('lightning-input');
        if (fileInput) {
            fileInput.value = null;
        }
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }

    isSuccessResponse(response) {
        return response.includes('Updated'); // Checks if Apex response contains 'Updated'
    }
}