import { LightningElement, wire, track,api  } from 'lwc';
import getFilesInfo from '@salesforce/apex/AvoUploadedFileDetails.getFilesInfo';
import SendFileDetails from '@salesforce/apex/AvoUploadedFileDetails.SendFileDetails';
import { refreshApex } from '@salesforce/apex';
export default class AvoSalesforceFilesToSharePoint extends LightningElement {
    @api recordId; // This property will hold the LinkingID passed from the Flow
    @api inputValue; // This property will receive the value from the Flow
    @track numberOfFiles = 0;
    @track isLoading = false; // Use to show/hide the loading spinner
    @track totalFileSizeWithUnit = '';
    @track files = [];
    @track paginatedFiles = [];
    @track currentPage = 1;
    @track pageSize = 10;
    @track totalPages = 0;
    @track searchKey = '';
    @track sortedBy;
    @track sortedDirection = 'asc';
    @track showMessage = false;
    message = '';
    //raj
    @track selectedFileIds = [];

// Handle row selection from datatable
handleRowSelection(event) {
    const selectedRows = event.detail.selectedRows;
    this.selectedFileIds = selectedRows.map(row => row.ContentDocumentId);
}



    //end raj

    
    columns = [
       // { label: 'LinkingId', fieldName: 'LinkingId', type: 'text', sortable: true,hidden: false},
       // { label: 'ContentDocumentId', fieldName: 'ContentDocumentId', type: 'text', sortable: true,hidden: false },
        { label: 'File name', fieldName: 'name', type: 'text', sortable: true },
        { label: 'Object name', fieldName: 'objectType', type: 'text', sortable: true },
        { label: 'Uploaded by', fieldName: 'uploadedBy', type: 'text', sortable: true },
        { label: 'Date', fieldName: 'createdDate', type: 'date', sortable: true },
        { label: 'File size', fieldName: 'fileSizeWithUnit', type: 'text', sortable: true }
    ];

    wiredFilesResult;
    @wire(getFilesInfo, { inputValue: '$inputValue',recordId: '$recordId'  })
    wiredFilesInfo(result) {
        this.wiredFilesResult = result; // Store the entire response for refresh purposes
        const { data, error } = result;
        this.isLoading = true;
        // Print inputValue and recordId
        console.log('inputValue:', this.inputValue);
        console.log('recordId:', this.recordId);
        if (data) {
            this.files = data.files; // Assume your data structure has these fields
            this.numberOfFiles = data.numberOfFiles;
            this.totalFileSizeWithUnit = data.totalFileSize;
            this.applyFilters(); // Apply any transformations or filtering to the data
            this.isLoading = false;
        } else if (error) {
            console.error('Error:', error);
            this.isLoading = false;
        }
    }

    applyFilters() {
        let filteredFiles = this.files;
    
        // Filter based on searchKey
        if (this.searchKey) {
            const searchLower = this.searchKey.toLowerCase();
            filteredFiles = filteredFiles.filter(file =>
                file.name.toLowerCase().includes(searchLower) ||
                file.objectType.toLowerCase().includes(searchLower) ||
                file.uploadedBy.toLowerCase().includes(searchLower)
            );
        }
    
        // Sort the data
        if (this.sortedBy) {
            filteredFiles = [...filteredFiles].sort((a, b) => {
                const fieldA = a[this.sortedBy];
                const fieldB = b[this.sortedBy];
                const isReverse = this.sortedDirection === 'asc' ? 1 : -1;
    
                return fieldA < fieldB ? -1 * isReverse : (fieldA > fieldB ? 1 * isReverse : 0);
            });
        }
    
        // Update total number of files and total pages
        this.numberOfFiles = filteredFiles.length;
        this.totalPages = Math.ceil(this.numberOfFiles / this.pageSize);
    
        // Calculate total file size for filtered files
        let totalFileSizeBytes = filteredFiles.reduce((total, file) => total + file.fileSize, 0);
        this.totalFileSizeWithUnit = this.formatFileSize(totalFileSizeBytes);
    
        // Update current page and paginated files
        this.currentPage = 1; // Reset to first page after filtering
        this.updatePaginatedFiles(filteredFiles);
    }
    
    // Utility function to format file size
    formatFileSize(fileSizeBytes) {
        if (fileSizeBytes >= 1024 * 1024 * 1024) {
            return (fileSizeBytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
        } else if (fileSizeBytes >= 1024 * 1024) {
            return (fileSizeBytes / (1024 * 1024)).toFixed(2) + ' MB';
        } else if (fileSizeBytes >= 1024) {
            return (fileSizeBytes / 1024).toFixed(2) + ' KB';
        } else {
            return fileSizeBytes + ' B';
        }
    }
    

    updatePaginatedFiles(filteredFiles = this.files) {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = this.currentPage * this.pageSize;
        this.paginatedFiles = filteredFiles.slice(start, end);
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
        this.applyFilters();
    }

    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.applyFilters();
    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedFiles();
        }
    }

    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedFiles();
        }
    }

    fetchFiles() {
        this.isLoading = true;
        getFilesInfo({ inputValue: this.inputValue,recordId: this.recordId })
            .then(result => {
                this.files = result.files; // Store original data
                this.applyFilters(); // Apply search and sort when data changes
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error:', error);
                this.isLoading = false;
            });
    }
    moveFiles() {
        // Get selected rows from datatable directly
        const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
    
        if (selectedRows.length === 0) {
            this.message = 'Please select at least one file to move.';
            this.showMessage = true;
            setTimeout(() => {
                this.showMessage = false;
            }, 3000);
            return;
        }
    
        const linkingIDs = selectedRows.map(file => file.LinkingId);
        const contentDocumentIds = selectedRows.map(file => file.ContentDocumentId);
    
        console.log('Selected Linking IDs:', linkingIDs);
        console.log('Selected ContentDocument IDs:', contentDocumentIds);
    
        this.isLoading = true;
        let promises = [];
    
        for (let i = 0; i < linkingIDs.length; i++) {
            promises.push(SendFileDetails({ 
                linkingId: linkingIDs[i], 
                contentDocumentId: contentDocumentIds[i] 
            }));
        }
    
        Promise.all(promises)
            .then(() => {
                this.message = 'Selected files have been moved successfully.';
                this.showMessage = true;
                refreshApex(this.wiredFilesResult);
            })
            .catch(error => {
                console.error('Error:', error);
                this.message = 'An error occurred while moving files.';
                this.showMessage = true;
            })
            .finally(() => {
                this.isLoading = false;
                setTimeout(() => {
                    this.showMessage = false;
                }, 5000);
            });
    }
        

    moveFiles1() {
        this.isLoading = true;
        console.log('Start Moving files...');

       

        // Collect ContentDocumentId values from the paginatedFiles
        // retreive from one page
        //const linkingIDs = this.files.map(file => file.id);
        //const linkingIDsString = this.files.map(file => file.id).join(',');

        
        //const arrayOfValues = linkingIDsString.split(",");
       // const uniqueArray = [...new Set(arrayOfValues)];
        //const uniquelinkingIDs = uniqueArray.join(",");
        // Extract unique file Ids
        //const uniquelinkingIDs = [...new Set(this.files.map(file => file.LinkingId))];   
        //const uniqueContentDocumentIds = [...new Set(this.files.map(file => file.ContentDocumentId))];  
        const linkingIDs = this.files.map(file => file.LinkingId);
        const ContentDocumentIds = this.files.map(file => file.ContentDocumentId);
        console.log(linkingIDs);
        console.log(ContentDocumentIds);
        let promises = [];

        for (let iCount = 0; iCount < linkingIDs.length; iCount++) {
            let linkingId = linkingIDs[iCount];
            let contentDocumentId = ContentDocumentIds[iCount]; // Ensure this array is defined and has the same length as linkingIDs
        
            // Create a promise for each file detail sending operation
            let promise = SendFileDetails({ linkingId, contentDocumentId });
            promises.push(promise);
        }
        
        // Use Promise.all to wait for all promises to resolve
        Promise.all(promises)
            .then(() => {
               
               // All SendFileDetails operations were successful
                this.message = 'All files have been moved successfully';
                this.showMessage = true;

                // Refresh data from @wire service
                refreshApex(this.wiredFilesResult);

               
            })
            .finally(() => { // Use finally to hide loading indicator whether promises resolved or rejected
                this.isLoading = false; // Stop loading regardless of the outcome
                setTimeout(() => {
                    this.showMessage = false;
                }, 9000);
            })
            .catch(error => {
                this.isLoading = false;
                // At least one SendFileDetails operation failed
                // Handle errors here, for example:
                this.message = 'An error occurred while moving the files';
                this.showMessage = true;
        
                // Optionally, hide the message after a certain time
                setTimeout(() => {
                    this.showMessage = false;
                }, 9000);
        
                // Log or handle error details
                console.error('Error moving files:', error);
            });
        /*for (let iCount = 0; iCount < linkingIDs.length; iCount++) {
            let linkingId = linkingIDs[iCount];
            let contentDocumentId = ContentDocumentIds[iCount];
            SendFileDetails({ linkingId, contentDocumentId })
            .then(() => {
               // fetchFiles();
                message = 'Files have been moved successfully';
                this.showMessage = true;

               
            })
            .catch(error => {
            // console.error('Error moving files with LinkingId ' + linkingId + ' and ContentDocumentId ' + contentDocumentId + ':', error);
                // Handle any errors, such as showing an error message
            });
        }*/
       


        /* let linkingId = 'a1a76000000RWY3AAO'; // Replace 'yourLinkingId' with actual value
        let contentDocumentId = '06976000002HzQCAA0'; // Replace 'yourContentDocumentId' with actual value

        SendFileDetails({ linkingId, contentDocumentId })
        .then(() => {
            fetchFiles();
            message = 'Files have been moved successfully';
            this.showMessage = true;

            // Automatically hide the message after 3 seconds
            setTimeout(() => {
                this.showMessage = false;
            }, 3000);
            //console.log('Files with LinkingId ' + linkingId + ' and ContentDocumentId ' + contentDocumentId + ' have been moved successfully');
            // You might want to refresh the file list or show a success message here
        })
        .catch(error => {
           // console.error('Error moving files with LinkingId ' + linkingId + ' and ContentDocumentId ' + contentDocumentId + ':', error);
            // Handle any errors, such as showing an error message
        });
        // Iterate over each linkingId and call transferDocumentIds for each
       linkingIDs.forEach((linkingId, index) => {
            const contentDocumentId = ContentDocumentIds[index];
            console.log('Files with LinkingId ' + linkingId + ' and ContentDocumentId ' + contentDocumentId );
            SendFileDetails({ linkingId: linkingId, contentDocumentId: contentDocumentId })
            .then(() => {
                console.log('Files with LinkingId ' + linkingId + ' and ContentDocumentId ' + contentDocumentId + ' have been moved successfully');
                // You might want to refresh the file list or show a success message here
            })
            .catch(error => {
                console.error('Error moving files with LinkingId ' + linkingId + ' and ContentDocumentId ' + contentDocumentId + ':', error);
                // Handle any errors, such as showing an error message
            });
        });*/
        // Call the Apex method
      /*SendFileDetails({ recordIds: uniquelinkingIDs })
        .then(() => {
            console.log('Files have been moved successfully '+uniquelinkingIDs);
            // You might want to refresh the file list or show a success message here
        })
        .catch(error => {
            console.error('Error moving files:', error);
            // Handle any errors, such as showing an error message
        });*/

       // console.log('Completed Moving files...');
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }
   
}