# Sitecore VSTS Templates
This repository contains various build and release templates to jumpstart a Sitecore deployment configuration on Visual Studio Online (VSTS).

Clone/fork this repository to your local machine in order to import the definitions.

## Build Templates

From a VSTS instance:

1. First, you need to get the **Project ID**.
   1. Log in to the VSTS project from a browser.
   2. Once authenticated, visit **https://<VSTS Project URL>/_apis/projects** in a browser window.
   3. This will output all current projects in JSON format. Look for the project with the proper **"Name"**, then find the corresponding **"id"** property. 
2. Navigate to the desired template in the repository at `~\BuildTemplates\`
3. Edit this *.json file
4. Scroll all the way to the bottom and find the **"project"** property.
   1. Modify the **"id"** property to match the GUID you found in step **1** above.
5. Save your modified *.json file.
6. From VSTS online, navigate to the Builds page (Page name: **Build pipelines**)
7. Click **"+ Import"**
8. Click **"Browse..."**
9. Click **"Import"**
10. When the build definition loads, it will require some attention.
    1. **Process**
       1. Change name: Remove **"-import"** from the end of the name.
	   2. Select the proper **"Agent queue"**. This will likely be **"Hosted VS2017"**.
    2. **Get sources**
       1. It _should_ automatically select the current projects **VSTS Git** repo. If not, select the proper **source**.
	   2. Verify it is pulling from the proper branch, **master** by default.
11. Click **"Save & queue > Save"**
    1. No folder selection is required.
    2. No comment is required.