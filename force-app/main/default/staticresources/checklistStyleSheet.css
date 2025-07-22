/*Overall Layout and Styling*/

body {
 
	color: #171717;
}
h1, h2, h3, h4, h5, h6, a {

	color: #0070d2;
}


/*Sections*/

.bgck-section-wrapper {

	position: relative;
    border-bottom: 1px solid rgb(216, 221, 230);
    width: 80%;
    margin: 0 auto;
}

.bgck-section-header {
	padding: 2%;
}

.bgck-header-container {
	display: flex;
	flex-direction: row;
	flex-wrap: nowrap;
	justify-content: space-between;
	align-items: center;
  	color: #0070d2; 
}


.bgck-section-number {
    padding-right: .5rem;
}

.bgck-section-icon {

  width: 3.5rem;
  height: 2.5rem;
  
}

#closed.bgck-section-icon::before, #open.bgck-section-icon::before {
  content: '\2190';
  font-size: 2.5rem;
}

#open.bgck-section-icon, .bgck-header-container:hover #closed.bgck-section-icon {
  
  transform: rotate(-0.25turn);
  color: grey;
}

#complete.bgck-section-icon::before {
  content: '\2714';
  font-size: 2.5rem;

}

/*Questions*/

.bgck-question-body {
	display: flex;
}

.bgck-question-number {
 	font-weight: bold;
    margin-right: 0.5rem;
}

.bgck .slds-required {
	display: block;
	padding: 0.25rem 0;
}

.bgck .slds-form-element__control {
	margin-top: 1rem;
}

.bgck .hide-labels .slds-form-element__label {
	position:absolute;
	left:-10000px;
	top:auto;
	width:1px;
	height:1px;
	overflow:hidden;
}

.bgck-percent::after
 {
 	content: '%';
	position: absolute;
	top: 25%;
	right: -1.5rem;
  }

	.bgck-currency::after {
		content: '$';
		position: absolute;
		top: 24%;
		left: -1rem;
	}

  .bgck-percent, .bgck-currency {
      position: relative;
  }

	.bgck-is-disabled {

		background-color: rbg(224,229,238);
		cursor: not-allowed;
	}

	.bgck-help-text{
		position: absolute;
		width: 20rem;
		bottom: 5rem;
		left: -1rem;
	}
	.bgck-help-icon {
		padding-top: 1rem;
	}

	..bgck-help-icon:hover + .bgck-help-text {
		display: block;
	}

/*Warnings*/
.warning.slds-popover {

  position: absolute;
  bottom: 10px;
  right: 15%;
  
}

/*Buttons*/
.bgck.slds-button + .slds-button {
  margin-left: none;
  
}

/* Modal popup for record view */
.record.slds-spinner_container {
	background-color: transparent;
}
.slds-modal .slds-required {
	display: inline;
	padding: 0;
}
.uiLabel .required {
	color: rgb(194, 57, 52);
	float: left;
}
.slds-modal .slds-form-element__control {
	margin-top: 0;
}

/* Print Stylesheet */

@media print {

	/* Radio Buttons won't print properly without this */
	.slds-radio [type=radio]:checked+.slds-radio--faux:after, 
	.slds-radio [type=radio]:checked~.slds-radio--faux:after, 
	.slds-radio [type=radio]:checked+.slds-radio__label .slds-radio--faux:after {
		    border: 4px solid rgb(21, 137, 238);
	}
}