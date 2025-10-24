import { LightningElement, wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import Static Resource PapaParse
import PAPA_PARSE_JS from '@salesforce/resourceUrl/papaparse';

// Import Methods
import getTankTypes from '@salesforce/apex/TankLoaderController.getTankTypes';
import createTanks from '@salesforce/apex/TankLoaderController.createTanks';

export default class TankMassLoader extends LightningElement {
    
    // --- Properties for Combobox (Step 1) ---
    @track tankTypeOptions = [];
    selectedTankTypeId;

    // --- Properties File Upload (Step 2) ---
    acceptedFormats = ['.csv'];
    @track csvFile;
    @track fileName = '';

    // --- UI Status ---
    isLoading = false;
    
    /**
     * Set the Tank Types list using @wire for the combobox.
     */
    @wire(getTankTypes)
    wiredTankTypes({ error, data }) {
        if (data) {
            // Transform the list to a combobox format
            this.tankTypeOptions = data.map(type => {
                return { label: type.Name, value: type.Id };
            });
        } else if (error) {
            this.showToast('Error', 'Error loading Tank Types', 'error');
        }
    }

    /**
     * Save the selected Tank Type ID in Step 1.
     */
    handleTankTypeChange(event) {
        this.selectedTankTypeId = event.detail.value;
    }

    /**
     * Read the file from the <input type="file">
     */
    handleFileChange(event) {
        if (event.target.files.length > 0) {
            this.csvFile = event.target.files[0];
            this.fileName = event.target.files[0].name;
        }
    }
    
    /**
     * Validate if the "Process" button should be enabled or not.
     */
    get processButtonDisabled() {
        // It is enabled if a Tank Type is selected and a CSV file is uploaded
        return !this.selectedTankTypeId || !this.csvFile;
    }

    /**
     * Main logic: Load PapaParse, read the CSV and call Apex.
     */
    async handleProcessCSV() {
        this.isLoading = true;

        // Load the PapaParse library from the Static Resource
        try {
            await loadScript(this, PAPA_PARSE_JS);
        } catch (error) {
            this.showToast('Error of Loading', 'Error loading the CSV library (PapaParse).', 'error');
            this.isLoading = false;
            return;
        }

        // Use PapaParse to read the file
        Papa.parse(this.csvFile, {
            header: true, // Assume the CSV has headers (e.g. "Serial Number")
            skipEmptyLines: true,
            complete: (results) => {
                this.callApexToCreateTanks(results.data);
            },
            error: (error) => {
                this.showToast('Error of CSV', error.message, 'error');
                this.isLoading = false;
            }
        });
    }

    /**
     * Call the Apex method passing the JSON and the Tank Type ID.
     */
    async callApexToCreateTanks(csvData) {
        // Convert the CSV data (a PapaParse object) to a JSON string
        const jsonTanks = JSON.stringify(csvData);

        try {
            // Call the 'createTanks' Apex method
            const resultMessage = await createTanks({ 
                jsonTanks: jsonTanks, 
                tankTypeId: this.selectedTankTypeId 
            });

            if (resultMessage.startsWith('Success')) {
                this.showToast('Success', resultMessage, 'success');
            } else {
                // Show the error that came from Apex (e.g. "Field X required")
                this.showToast('Error of Creation', resultMessage, 'error');
            }
            
        } catch (error) {
            this.showToast('Error of System', error.body ? error.body.message : error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Utility to show notifications (toasts).
     */
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}