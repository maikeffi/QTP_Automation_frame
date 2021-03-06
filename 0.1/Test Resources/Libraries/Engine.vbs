Option Explicit

PUBLIC Data		'Holds Test Data. Its loaded each time a new test case 
				'is executed. See Run method of clsEngine.
				
PUBLIC Engine : Set Engine = New clsEngine

Class clsEngine
    Private bCustom				'.NETFactory Form: Custom Execution
	Private bRestart			'.NETFactory Form: Restart Execution (Next release)
	Private bResume				'.NETFactory Form: Resume Execution (Next release)
	Private intContext			'Reporter LogEvent (See SetReporterContext)
	Private oMe					'Region Reference
	Private Implementor			'Instance of Class clsImplementor (Implementor.vbs)
	Private TestData			'Instance of Class clsTestData (Data.vbs)


	Public vVersion				'QTP Version

	'<comment>
	'	<name>
	'		Default Function Run
	'	</name>
	'	<summary>
	'		Executes all test cases from the excel spreadsheet.
	'	</summary>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'		Init
	'		SetReporterContext
	'		UnloadSettings
	'		clsData.Load
	'		clsImplementor.Run
	'	</seealso>
	'</comment>
	Public Default Function Run()
 		'If all global settings loaded correctly then, start implementing test cases
	 	If Init Then
			'Loop until all test cases have completed execution
			Do
				'Load current test case data
				Set Data = TestData.Load

				'If Data is no longer a dictionary object, it means that all the test
				'cases have finished executing or no test cases were selected in the
				'Excel spreadsheet for execution.
				'This will exit the loop and unload all global variables instantiated
				'in the LoadGlobals method.
                If Data Is Nothing Then Exit Do

				'Create Child Node
				SetReporterContext TestData.sCurrentTest
				
				'Implement the Test case <see clsImplementor>
				Implementor.Run
				
				'Return to Parent Node
				Reporter.UnSetContext
			Loop

			'Unload test settings
			UnloadSettings			
		End If	
	End Function

	'<comment>
	'	<name>
	'		Function Init
	'	</name>
	'	<summary>
	'		Verifies if all the initialization settings load correctly
	'	</summary>
	'	<return type="Boolean">
	'		True: All settings initialized correctly
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'		IsProductVersionAllowed
	'		IsFormConform
	'		LoadSettings
	'	</seealso>
	'</comment>
	Private Function Init() 'As Boolean
 		Init = False

		'Check for QTP Version
 		If IsProductVersionAllowed Then
			'Check for Form's status
			If IsFormConform Then
				'Check for Settings Status
				If LoadSettings Then
					Init = True
				End If
			End If
		End If

	End Function
	
	'<comment>
	'	<name>
	'		Function LoadSettings
	'	</name>
	'	<summary>
	'		Verifies if all the global objects load correctly
	'	</summary>
	'	<return type="Boolean">
	'		True: All global objects loaded correctly
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private Function LoadSettings() 'As Boolean
 		LoadSettings = False

		On Error Resume Next

			'Instance of Class clsData (Data Object)
			Set TestData = New clsData
			'Instance of Class clsImplementor (Implementation Rules + Hierarchy Builder)
			Set Implementor = New clsImplementor

			If Err.Number = 0 Then LoadSettings = True
            
		On Error Goto 0
		
	End Function

	'<comment>
	'	<name>
	'		Function UnloadSettings
	'	</name>
	'	<summary>
	'		Unloads all the global objects
	'	</summary>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private Sub UnloadSettings()
		On Error Resume Next
		
			Set TestData = Nothing
			Set Implementor = Nothing

		On Error Goto 0
	End Sub

	'<comment>
	'	<name>
	'		Function IsProductVersionAllowed
	'	</name>
	'	<summary>
	'		Verifies if the QTP version is a version compatible with 
	'		Relevant Codes [1] One
	'	</summary>
	'	<return type="Boolean">
	'		True: Version is compatible
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'		AlertTerminate
	'	</seealso>
	'</comment>
	Private Function IsProductVersionAllowed() 'As Boolean
 		Dim vVersion, ProductVersionMajor, ProductVersionMinor

		IsProductVersionAllowed = True

		'QTP Product Version
		vVersion = Environment.Value("ProductVer")

        ProductVersionMajor = Split(vVersion, ".")(0)
		ProductVersionMinor = Split(vVersion, ".")(1)
		
		'Disallow QTP versions less than 9 to execute this framework
		If CInt(ProductVersionMajor) < 9 Then
			AlertTerminate micFail, "Upgrade QuickTest!", "The " & _
				"minimum QuickTest version required to run this framework is" & _
				" 9.2. Your QuickTest version " & vVersion & " does not " & _
				"comply to the minimum requirements. The test will now exit.", vbCritical
			IsProductVersionAllowed = False
		End If

		Me.vVersion = vVersion
	End Function
	
	'<comment>
	'	<name>
	'		Sub SetReporterContext
	'	</name>
	'	<summary>
	'		Creates a node-level in the results log
	'	</summary>
	'	<param name="sTestCaseName" type="String">
	'		Name of the test that is inheriting a results node.
	'	</param>
	'	<author>
	'		Yaron Assa (AvancedQTP, SolmarKN)
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Public Sub SetReporterContext(ByVal sTestCaseName)
		Dim dicMetaDescription, vVersion

		vVersion = Me.vVersion
		
		'dicMetaDescription will hold our new node's details
		Set dicMetaDescription = CreateObject("Scripting.Dictionary") 
		
		'Set node status
		dicMetaDescription("Status") = micDone 
		
		'Set node's header
		dicMetaDescription("PlainTextNodeName") = sTestCaseName
		
		''Set the node's details. HTML is allowed
		dicMetaDescription("StepHtmlInfo") = "Initiating " & sTestCaseName
		
		'Some backdoor settings:
		dicMetaDescription("DllIconIndex") = 206
		dicMetaDescription("DllIconSelIndex") = 206

		dicMetaDescription("DllPAth") = "C:\Program Files\Mercury Interactive\QuickTest Professional\bin\ContextManager.dll"
		
		If Split(vVersion, ".")(0) = 9 And Split(vVersion, ".")(1) >= 0 And Split(vVersion, ".")(1) <= 2 Then
			dicMetaDescription("DllPAth") = "C:\Program Files\HP\QuickTest Professional\bin\ContextManager.dll"
		End If
        
		'Actually do the report, and get the new report node ID
		intContext = Reporter.LogEvent("User", dicMetaDescription, Reporter.GetContext) 
		
		'Set the new report node as a parent
		'From now on, all reports will be added under this node
		Reporter.SetContext intContext
	End Sub

	'<comment>
	'	<name>
	'		Function IsFormLoaded
	'	</name>
	'	<summary>
	'		Loads a custom user-form and takes some inputs from the
	'		user. {Under construction}
	'	</summary>
	'	<return type="Boolean">
	'		True: User selected the correct values and clicked Execute Engine
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private Function IsFormConform()
		Dim oButtonStartEngine, oButtonStopEngine, oDialogResult, oForm, oGroupBox
		Dim oLabel, oPoint, oRadioRestart, oRadioResume, oRadioCustom, oTextBox, x, y

		IsFormConform = False
		
		With DOTNetFactory
			'StartEngine Button = New System.Windows.Forms.Button
			Set oButtonStartEngine = .CreateInstance(Assembly & ".Button", Assembly)
			'StopEngine Button = New System.Windows.Forms.Button
			Set oButtonStopEngine = .CreateInstance(Assembly & ".Button", Assembly)
			'DialogResult Instance = New System.Windows.Forms.DialogResult
			Set oDialogResult = .CreateInstance(Assembly & ".DialogResult", Assembly)
			'Form Object = New System.Windows.Forms.Form
			Set oForm = .CreateInstance(Assembly & ".Form", Assembly)
			'GroupBox Object = New System.Windows.Forms.GroupBox
			Set oGroupBox = .CreateInstance(Assembly & ".GroupBox", Assembly)
			'Label Object = New System.Windows.Forms.Label
			Set oLabel = .CreateInstance(Assembly & ".Label", Assembly)
			'Point Object = New System.Drawing.Point
			Set oPoint = .CreateInstance("System.Drawing.Point", "System.Drawing", x, y)
			'Restart Engine Button = New System.Windows.Forms.RadioButton
			Set oRadioRestart = .CreateInstance(Assembly & ".RadioButton", Assembly)
			'Resume Engine Button = New System.Windows.Forms.RadioButton
			Set oRadioResume = .CreateInstance(Assembly & ".RadioButton", Assembly)
			'Custom Test Execution Button = New System.Windows.Forms.RadioButton
			Set oRadioCustom = .CreateInstance(Assembly & ".RadioButton", Assembly)
			'Custom Test Execution TextBox = New System.Windows.Forms.TextBox
			Set oTextBox = .CreateInstance(Assembly & ".TextBox", Assembly)
		End With

		'RadioRestart Properties
		With oRadioRestart
			.AutoSize = True
			.Enabled = False
			'RadioButton name:
			.Name = "oRadioRestart"
			.TabIndex = 2
			.TabStop = True
			'Adjacent text:
			.Text = "Restart"
			.UseVisualStyleBackColor = True
			.Width = 59
			.Height = 17
		End With
		'RadioRestart Location on oForm
		With oPoint
			.x = 15
			.y = 25
		End With
        oRadioRestart.Location = oPoint

		'RadioResume Properties
		With oRadioResume
			.AutoSize = True
			.Enabled = False
			'RadioButton name:
			.Name = "oRadioResume"
			.TabIndex = 3
			.TabStop = True
			'Adjacent text:
			.Text = "Resume"
			.UseVisualStyleBackColor = True
			.Width = 64
			.Height = 17
		End With
		'RadioResume location on oForm
		With oPoint
			.x = 104
			.y = 25
		End With
		oRadioResume.Location = oPoint

		'RadioCustom Properties
		With oRadioCustom
			.AutoSize = True
			.Checked = True
			'RadioCustom name:
			.Name = "oRadioCustom"
			.TabIndex = 4
			.TabStop = True
			'Adjacent text:
			.Text = "Custom"
			.UseVisualStyleBackColor = True
			.Width = 60
			.Height = 17
		End With
		'RadioCustom location on oForm
		With oPoint
			.x = 196
			.y = 25
		End With
		oRadioCustom.Location = oPoint

		'GroupBox Properties
		With oGroupBox
			'Add Restart RadioButton
			.Controls.Add oRadioRestart
			'Add Resume RadioButton
			.Controls.Add oRadioResume
			'Add Custom RadioButton
			.Controls.Add oRadioCustom
			'Groupbox name:
			.Name = "oGroupBox"
			.TabIndex = 5
			.TabStop = False
			'Groupbox text:
			.Text = "Select Execution Type:"
			.Width = 315
			.Height = 60
		End With
		'GroupBox location on oForm
		With oPoint
			.x = 26
			.y = 15
		End With
		oGroupBox.Location = oPoint

		'Label Properties
		With oLabel
			.AutoSize = True
			'Label name:
			.Name = "oLabel"
			.TabIndex = 6
			'Label text:
			.Text = "Enter Custom Rows (Seperated by a Comma):"
			.Width = 103
		End With
		'Label position on oForm
		With oPoint
			.x = 26
			.y = 86
		End With
		oLabel.Location = oPoint

		'oTextBox Properties
		With oTextBox
			.MultiLine = True
			.Enabled = False
			'Textbox name:
			.Name = "oTextBox"
			'Current text:
			.Text = "This control will be available in the next release."
			.TabIndex = 1
			.Width = 312
			.Height = 41
		End With
		'oTextBox location on oForm
		With oPoint
			.x = 29
			.y = 105
		End With
		oTextBox.Location = oPoint

		'oButtonStartEngine Properties
		With oButtonStartEngine
			'Button name:
			.Name = "oButtonStartEngine"
			.Enabled = True
			.TabIndex = 0
			'Button text:
			.Text = "Execute Engine!"
			.UseVisualStyleBackColor = True
			.Width = 117
			'Set DialogResult = OK
			.DialogResult = oDialogResult.OK
		End With
		'Button location on oForm
		With oPoint
			.x = 224
			.y = 157
		End With
		oButtonStartEngine.Location = oPoint

		'oButtonStopEngine Properties
		With oButtonStopEngine
			'Button name:
			.Name = "oButtonStopEngine"
			.Enabled = True
			.TabIndex = 7
			'Button text:
			.Text = "Stop Engine!"
			.UseVisualStyleBackColor = True
			.Width = 117
			'Set DialogResult = Cancel
			.DialogResult = oDialogResult.Cancel
		End With
		'oButtonStopEngine location on oForm
		With oPoint
			.x = 101
			.y = 157
		End With
		oButtonStopEngine.Location = oPoint

		'oForm Properties
		With oForm
			'Set Form's Cancel Button
			.CancelButton = oButtonStartEngine
			'Form title
			.Text = "Execution Selector"
			'Form name
			.Name = "oForm"
			.Width = 375
			.Height = 218
			.ResumeLayout False
			.PerformLayout
		End With

		'Add Custom controls to oForm
		With oForm.Controls
			.Add oGroupBox
			.Add oButtonStartEngine
			.Add oButtonStopEngine
			.Add oLabel
			.Add oTextBox
		End With

		'Display() Form
		oForm.ShowDialog

		'One of the RadioButtons must be checked to initiate execution
		'Custom: will run custom test cases from the Form's textbox and 
		'	test cases in Excel with "Execute Y" flag
		'Restart: will start execution from the first testcase to the last
		'Resume: will start execution from the last executed test case
		If oRadioRestart.Checked Then bRestart = True	'Available in the next release
		If oRadioResume.Checked Then bResume = True		'Available in the next release
		If oRadioCustom.Checked Then bCustom = True		'Available in the current release

		'If the user clicks StartEngine, then start execution
		If oForm.DialogResult = "OK" Then
			If bCustom Then
				IsFormConform = True
			End If
		End If

		'Release
		Set oButtonStartEngine = Nothing
		Set oButtonStopEngine = Nothing
		Set oDialogResult = Nothing
		Set oForm = Nothing
		Set oGroupBox = Nothing
		Set oLabel = Nothing
		Set oPoint = Nothing
		Set oRadioRestart = Nothing
		Set oRadioResume = Nothing
		Set oRadioCustom = Nothing
		Set oTextBox = Nothing
	End Function

	'<comment>
	'	<name>
	'		Get Assembly
	'	</name>
	'	<summary>
	'		Assembly name for .NETFactory Objects
	'	</summary>
	'	<return type="Text">
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private Property Get Assembly() 'As String
		Assembly = "System.Windows.Forms"
	End Property

	'<comment>
	'	<name>
	'		Get iIterations
	'	</name>
	'	<summary>
	'		
	'	</summary>
	'	<return type="Integer">
	'		Number of iterations to run per test case.
	'	</return>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Public Property Get iIterations() 'As Integer
		'Available in the next release
	End Property

	'<comment>
	'	<name>
	'		Sub Class_Terminate
	'	</name>
	'	<summary>
	'	</summary>
	'	<author>
	'		Kannan Maikeffi
	'	</author>
	'	<seealso>
	'	</seealso>
	'</comment>
	Private Sub Class_Initialize()
		CreateObject("Shell.Application").MinimizeAll
	End Sub
End Class
