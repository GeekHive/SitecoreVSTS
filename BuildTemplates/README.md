[<< Back to main README.md](../README.md)

## Import Build Template into VSTS Project

<details><summary>Click to toggle contents...</summary>

From a VSTS instance:

1. First, you need to get the **Project ID**.
   1. Log in to the VSTS project from a browser.
   2. Once authenticated, visit **https://\<VSTS Project URL\>/_apis/projects** in a browser window.
   3. This will output all current projects in **JSON** format. Look for the project with the proper **"Name"**, then find the corresponding **"id"** property, remember this. 
2. Navigate to the desired template in your local repository at `~\BuildTemplates\`
   1. For IaaS builds, use *sitecore.vsts.build.IaaS.json*
   2. For PaaS buidls, use *TBD*
3. Edit this **\*.json** file
4. Scroll all the way to the bottom and find the **"project"** property.
   1. Modify the **"id"** property to match the GUID you found in step **1** above.
5. Save your modified **\*.json** file.
6. From VSTS online, navigate to the Builds page (Page name: **Build pipelines**)
7. Click **"+ Import"**
8. Click **"Browse..."**
9. Click **"Import"**
10. When the build definition loads, it will require some attention.
    1. **Process**
       1. Change name: Remove **"-import"** from the end of the name. For example, **"Base Build"**.
	   2. Select the proper **"Agent queue"**. This will likely be **"Hosted VS2017"**.
    2. **Get sources**
       1. It _should_ automatically select the current projects **VSTS Git** repo when you select this task. If not, select the proper **source**.
	   2. Verify it is pulling from the proper branch, **master** by default.
11. Click **"Save & queue > Save"**
    1. No folder selection is required.
    2. No comment is required.
	
This build template assumed you will be using **TDS Classic** and enable **Update Packages** (preferrably of _Items Only_) for your deployment. It also assumes that the output of the TDS project (targeted Web Project) is used as the primary artifact to promote to all environments. _The TDS Classic output of the web project produces more consistent configuration transformations._

</details>

### Build Process

Note the **Parameters**. The "Path to solution or packages.config" defaults to **\*\*\\*.sln** and "Artifact Name" defaults to **drop**. These are *linked* to some of the Build Tasks.

### Variables on Build Template

<details><summary>Click to toggle contents...</summary>

#### BuildPlatform
*   Default Value: **Any CPU**
*   This will likely not change

#### BuildConfiguration
*   Default Value: **Release**
*   This is the Solution Configuration you are targeting for VSTS builds. Release is _preferred_, though another may be accurate for your instance.

#### CullProjectFiles
*   Default Value: **False**
*   Dependent on: **EnableGitDeltaDeploy**
*   Possible Values: True or False
*   This is used with GitDeltaDeploys. It reduces the number of files included in the output to only changed files depending on GitDeltaDeploy configuration.

#### EnableGitDeltaDeploy
*   Default Value: **False**
*   Possible Values: True or False
*   To use this setting, be sure to add the [GitDeltaDeploy NuGet package](https://www.nuget.org/packages/Hedgehog.TDS.BuildExtensions.GitDeltaDeploy/) to all TDS projects. 

#### LastDeploymentGitTagname
*   Default Value: **"ProductionRelease"**
*   Dependent on: **EnableGitDeltaDeploy**
*   This is the tag that GitDeltaDeploy will reference when it performs it's delta of items and files. It will only include changed items/files between the current build and the commit with this tag.

#### LastProductionReleaseCommitId
*   Default Value: **(none)**
*   Dependent on: **EnableGitDeltaDeploy**
*   Instead of using the **LastDeploymentGitTagname**, you may instead wish to target a specific commit. Note: You will need to update the MS Build arguments to use a commit id instead of a tag name.

#### system.debug
*   Default Value: **true**
*   Possible Values: true or false
*   If true, this increases the verbosity of the build log output.

#### TDS_Key
*   Default Value: **"KEY"**
*   Enter your organizations TDS Classic Key in this field to allow the build server to perform a build via TDS Classic.

#### TDS_OWNER
*   Default Value: **"OWNER"**
*   Enter your organizations TDS Classic Owner in this field to allow the build server to perform a build via TDS Classic.

</details>

### Build Steps (Build Sitecore Solution)

<details><summary>Click to toggle contents...</summary>

#### Download GeekHive Scripts
*   Fields: No fields require attention.
*   This is an inline PowerShell script that pulls down the contents of https://github.com/GeekHive/SitecoreVSTS for use on the build. This step is **critical** if you wish to use these scripts further in the process: in further Build Steps or with the templated [Release Task Groups](ReleaseTaskGroups/README.md).

#### NuGet restore \*\*\\*.sln
*   Fields: Likely that no fields require attention.
*   This pulls in all NuGet packages based on the individual **packages.config** files referenced by each project.

#### Build solution \*\*\\.sln
*   Fields: 
    *   Visual Studio Version
	    *   Default Value: Visual Studio 2017
	    *   If you are building our your project on an earlier version, update to be correct.
	*   MSBuild Arguments
	    *   Default Value: /p:OutDir=$(Build.ArtifactStagingDirectory) /p:SkipInvalidConfigurations=true /p:LastDeploymentGitTagName=$(LastDeploymentGitTagName) /p:CustomGitDeltaDeploy=$(EnableGitDeltaDeploy) /p:CullProjectFiles=$(CullProjectFiles)
		*   Most of the arguments are driven by Build Variables, but you may want to modify "LastDeploymentGitTagName=$(LastDeploymentGitTagName)" if you instead choose to use "LastDeploymentGitCommitID=&(LastProductionReleaseCommitId)" instead and then update the Build Variable "LastProductionReleaseCommitId". If GitDeltaDeploy is not used, clear the LastDeployment* variables values and set "EnableGitDeltaDeploy" to "False".
*   This task builds the solution. Note, we typically rely on the output of the TDS project that points to the primary Web Project as our promoted build output.

#### Delete files from $(Build.ArtifactStagingDirectory)
*   Fields: 
    *   Contents
	    *   Default Value: *.dll *.pdb *.config *.xml App_Config
	    *   Enter the files you wish to remove from the promoted build artifact.
*   This task simply cuts down on the size of the promoted artifact. It isn't critical, but makes for a more slimmed down artifact.

#### Remove Files From TDS Package
*   Fields: 
    *   Script Path
	    *   Default Value: $(Build.ArtifactStagingDirectory)\SitecoreVSTS\Scripts\Build\Remove TDS Files\RemoveFiles.ps1
	    *   The path to the **RemoveFiles.ps1** script. 
		*   **Note: if the "Download GeekHive Scripts" task is used, this field does not need to be modified.
	*   Arguments
	    *   Default Value: -pathToPackages "$(Build.ArtifactStagingDirectory)\_Packages\TDS.Project"
		*   Modify the **TDS.Project** portion of the Arguments field to point to the relevant TDS Project.
*   You will likely have 1 or more of  these tasks. One is required for each TDS project unless a bundling is configured.

#### Publish Artifact: drop
*   Fields: Likely that no fields require attention.
*   This step promotes the artifacts to VSTS cloud for later consumption by Release Tasks, per environment.

</details>