@REM ================================================================================================
@REM =================================   Start: Configuration Area  =================================
@REM ================================================================================================

:MatrixConfiguration

	@REM 
	set "XlsToDbcConfig=1"

	@REM 
	set "DbcToXlsConfig=1"

	@REM The characters related to the message contained in the message column data,
	@REM used to match the message column
	set "MsgNameColumn=Msg Name"

	@REM The number of nodes in the network
	set /A NetworkNodesNum=14

	@REM the name of network management message
	set "MsgType_NM=NM"

	@REM the name of diagnostic message
	set "MsgType_Diag=Diag"

	@REM the name of normal message
	set "MsgType_Normal=Normal"

	@REM "1" means that signal grouping is enabled, "0" means that signal grouping is not enabled, 
	@REM signal grouping only supports one signal group, that is, all signals are placed in one signal group
	set "SignalGroupFlg=1"

	@REM 将电子表格转换为 Dbc 文件时，通信矩阵Sheet表的名字
	set "MatrixSheetName=Matrix"

	@REM 启用附加功能，生成节点交互图、底层通信报文结构体源代码
	set "OneIsAllFlg=1"

	@REM “1”表示在节点交互图显示节点和报文之间的交互
	@REM “0”表示在节点交互图显示节点、信号和报文之间的交互
	set "OnlyDisplayMsgGraphvizFlg=0"

@REM ================================================================================================
@REM =================================   End: Configuration Area  ===================================
@REM ================================================================================================


@REM ================================================================================================
@REM ====================================   Start: Process Area  ====================================
@REM ================================================================================================

:Expand
	@REM close command display
	@echo off

	@REM Enable delay expansion variable
	@SETLOCAL ENABLEDELAYEDEXPANSION

	@REM @REM Set the encoding to utf8
	@REM @chcp 65001

	@REM set batch windows title
	@title DBC and CSV file mutual conversion

	@REM display Conversion start time
	cls
	echo ====================================================================================================================
	echo                                          DBC and CSV file mutual conversion                                        
	echo ====================================================================================================================
	echo 				  ^|                 Start Conversion             ^|
	echo 				  ^|            Start Time: %TIME%	         ^|

	@REM Start the timer, record initial running time
	set /A startTime_m=(1%TIME:~3,2%-100)*60*1000 > nul
	set /A startTime_s=(1%TIME:~6,2%-100)*1000 > nul
	set /A startTime=%startTime_m%+%startTime_s%+%TIME:~9,2%*10 > nul

	@REM input file
	set "fullPathInputFile=%~f1"
	set "onlyExtensionInputFile=%~x1"
	set "onlyNameInputFile=%~n1"

	@REM 
	set "ConversionSuccessFlg=false"

	@REM 
	set xlsFileJudge=!onlyExtensionInputFile:~1,2!

	@REM 
	if "!xlsFileJudge!"=="xl" (

		@REM 
		set "onlyExtensionInputFile=.csv"

		@REM 
		goto XlsToCsv
	)

	@REM 
	:CsvFileConversion

		set "AutoToolOutputFile=AutoTool.bat"
		if exist !AutoToolOutputFile! ( del !AutoToolOutputFile! )

		@REM Judge the input file type
		if /i "!onlyExtensionInputFile!"==".csv" (
			@REM convert *.csv file to *.dbc file

			echo %0 %1 > !AutoToolOutputFile!

			if "!XlsToDbcConfig!"=="1" (

				goto Csv_To_Dbc
			)
		)^
		else if /i "!onlyExtensionInputFile!"==".dbc" (
			@REM convert *.dbc file to *.csv file

			echo %0 %1 > !AutoToolOutputFile!

			if "!OneIsAllFlg!"=="1" (

				call:OneIsAll !onlyNameInputFile!.dbc
			)

			if "!DbcToXlsConfig!"=="1" (

				goto Dbc_To_Csv
			)
		)^
		else (
			@REM condition is not stafisy, end conversion
			goto EndConversion
		)

@REM ================================================================================================
@REM ====================================   End: Process Area  ======================================
@REM ================================================================================================


@REM ================================================================================================
@REM ===================================   Start: End Conversion  ===================================
@REM ================================================================================================

@REM End of conversion
:EndConversion

	@REM Stop the timer
	set /A endTime_m=(1%TIME:~3,2%-100)*60*1000 > nul
	set /A endTime_s=(1%TIME:~6,2%-100)*1000 > nul
	set /A endTime=%endTime_m%+%endTime_s%+%TIME:~9,2%*10 > nul

	@REM Calculate the time difference
	if %endTime% LSS %startTime% (
		set /A interval=%startTime%-%endTime% > nul
	)^
	else (
		set /A interval=%endTime%-%startTime% > nul
	)
	set /A diff_second=%interval%/1000 > nul
	set /A diff_millisecond=(%interval%-diff_second*1000)/10 > nul

	@REM display conversion result
	if "!ConversionSuccessFlg!"=="true" (
		echo 				  ^|	          Conversion Complete	         ^|
		echo 				  ^|	         End Time: %TIME%	         ^|
		echo 				  ^|         Conversion Time: %diff_second%.%diff_millisecond% Seconds	 ^|
		echo 				  ^| Processed Messages:!messagesNum! ^| Processed Signals:!signalsNum!  ^|
		echo ====================================================================================================================
		echo                                        Conversion successful, congratulations                                      
		echo ====================================================================================================================
	)^
	else (
		echo ====================================================================================================================
		echo                                          Conversion failed, sorry                                     
		echo ====================================================================================================================
	)

	@REM Disable delay expansion variable
	SETLOCAL DISABLEDELAYEDEXPANSION
	ENDLOCAL

	@REM Enter any key to exit the batch script
	pause > nul
	exit

@REM ================================================================================================
@REM ====================================   End: End Conversion  ====================================
@REM ================================================================================================


@REM ================================================================================================
@REM ===================================   Start: DBC Conversion  ===================================
@REM ================================================================================================

@REM convert *.dbc file to *.csv file
:Dbc_To_Csv

	@REM 
	set outputFile=!onlyNameInputFile!.csv
	if exist %outputFile% (del %outputFile%)

	@REM 表头
	set "MatrixData_Row_1_Column_1=Msg Name"
	set "MatrixData_Row_1_Column_2=Msg Type"
	set "MatrixData_Row_1_Column_3=Msg ID"
	set "MatrixData_Row_1_Column_4=Msg Send Type"
	set "MatrixData_Row_1_Column_5=Msg Cycle"
	set "MatrixData_Row_1_Column_6=Msg Length"
	set "MatrixData_Row_1_Column_7=Signal Name"
	set "MatrixData_Row_1_Column_8=Signal Description"
	set "MatrixData_Row_1_Column_9=Byte Order"
	set "MatrixData_Row_1_Column_10=Start Byte"
	set "MatrixData_Row_1_Column_11=Start Bit"
	set "MatrixData_Row_1_Column_12=Signal Send Type"
	set "MatrixData_Row_1_Column_13=Bit Length"
	set "MatrixData_Row_1_Column_14=Data Type"
	set "MatrixData_Row_1_Column_15=Factor"
	set "MatrixData_Row_1_Column_16=Offset"
	set "MatrixData_Row_1_Column_17=Signal Min Phys"
	set "MatrixData_Row_1_Column_18=Signal Max Phys"
	set "MatrixData_Row_1_Column_19=Signal Min Bus"
	set "MatrixData_Row_1_Column_20=Signal Max Bus"
	set "MatrixData_Row_1_Column_21=Initial Value"
	set "MatrixData_Row_1_Column_22=Invalid Value"
	set "MatrixData_Row_1_Column_23=Inactive Value"
	set "MatrixData_Row_1_Column_24=Unit"
	set "MatrixData_Row_1_Column_25=Signal Value Description"
	set "MatrixData_Row_1_Column_26=Msg Cycle Time Fast"
	set "MatrixData_Row_1_Column_27=Msg repetitions"
	set "MatrixData_Row_1_Column_28=Msg Delay Time"

	@REM 
	set /A Matrix_TotalColumns=28

	@REM 目前支持解析26节点
	FOR /F "tokens=1-25* usebackq delims= " %%A in ("!fullPathInputFile!") do (

		set "tmpDbc_RowsData_1=%%A"
		set "tmpDbc_RowsData_2=%%B"

		if "!tmpDbc_RowsData_1!"=="BU_:" (

			set /A Matrix_RowsIndex+=1
			
			if NOT "!tmpDbc_RowsData_2!"=="" (

				set "tmpDbc_RowsData_3=%%C"
				set "tmpDbc_RowsData_4=%%D"
				set "tmpDbc_RowsData_5=%%E"
				set "tmpDbc_RowsData_6=%%F"
				set "tmpDbc_RowsData_7=%%G"
				set "tmpDbc_RowsData_8=%%H"
				set "tmpDbc_RowsData_9=%%I"
				set "tmpDbc_RowsData_10=%%J"
				set "tmpDbc_RowsData_11=%%K"
				set "tmpDbc_RowsData_12=%%L"
				set "tmpDbc_RowsData_13=%%M"
				set "tmpDbc_RowsData_14=%%N"
				set "tmpDbc_RowsData_15=%%O"
				set "tmpDbc_RowsData_16=%%P"
				set "tmpDbc_RowsData_17=%%Q"
				set "tmpDbc_RowsData_18=%%R"
				set "tmpDbc_RowsData_19=%%S"
				set "tmpDbc_RowsData_20=%%T"
				set "tmpDbc_RowsData_21=%%U"
				set "tmpDbc_RowsData_22=%%V"
				set "tmpDbc_RowsData_23=%%W"
				set "tmpDbc_RowsData_24=%%X"
				set "tmpDbc_RowsData_25=%%Y"
				set "tmpDbc_RowsData_26=%%Z"

				@REM 
				FOR /L %%Z in (2,1,26) do (
					
					if NOT "!tmpDbc_RowsData_%%Z!"=="" (
						set /A Matrix_TotalColumns+=1

						@REM 将每个节点作为一个列
						set "MatrixData_Row_1_Column_!Matrix_TotalColumns!=!tmpDbc_RowsData_%%Z!"
					)
				)

				goto ExitBULoop
			)
		)
	)
	:ExitBULoop

	@REM 解析报文和信号
	set "SignalAndMsgFlg=true"
	FOR /F "tokens=* usebackq skip=36" %%Z in ("!fullPathInputFile!") do (

		@REM 保存 Dbc 文件中的一行数据，该数据将在后面被解析成信号和报文
		set "tmpDbc_RowsData=%%Z"

		@REM 过滤 Dbc 文件中的空行
		if NOT "!tmpDbc_RowsData!"=="" (

			@REM 解析 BO_ 的报文 和 SG_ 的信号 
			if "!SignalAndMsgFlg!"=="true" (

				@REM Singal
				if NOT "!tmpDbc_RowsData!"=="!tmpDbc_RowsData:SG_=_!" (

					set /A Matrix_RowsIndex+=1
					set /A Matrix_TotalSignal+=1

					FOR /F "tokens=2-10* delims=:|@(,)[] " %%Q in ("!tmpDbc_RowsData!") do (

						@REM Signal Name
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_7=%%Q"

						@REM Byte Order
						set "tmpDbc_ByteOrder=%%T"
						if "!tmpDbc_ByteOrder:~0,1!"=="1" (
							set "MatrixData_Row_!Matrix_RowsIndex!_Column_9=Intel"
						)^
						else (
							set "MatrixData_Row_!Matrix_RowsIndex!_Column_9=Motorola"
						)

						@REM Start Byte
						set /A tmpDbc_StartByte=%%R/8
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_10=!tmpDbc_StartByte!"

						@REM Start Bit
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_11=%%R"

						@REM Bit Length
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_13=%%S"

						@REM Data Type
						if "!tmpDbc_ByteOrder:~1,1!"=="+" (
							set "MatrixData_Row_!Matrix_RowsIndex!_Column_14=Unsigned"
						)^
						else (
							set "MatrixData_Row_!Matrix_RowsIndex!_Column_14=Signed"
						)

						@REM Factor
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_15=%%U"

						@REM Offset
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_16=%%V"

						@REM Signal Min Phys
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_17=%%W"

						@REM Signal Max Phys
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_18=%%X"

						@REM Signal Min Bus
						call:DecToHex %%W
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_19=!HexValue!"

						@REM Signal Max Bus
						set "SigMaxBusFactor=%%U"
						set "SigMaxBusDividend=%%X"
						set "IntegerDividend="
						set "IntegerDivisor="
						set "DivisorDecimalNum=1"
						set "DividendDecimalNum=1"
						
						@REM CMD 不支持小数运算，所以需要将小数转换为整数
						if NOT "!SigMaxBusFactor!"=="!SigMaxBusFactor:.=_!" (

							set "DivisorDecimalStopFlg=false"
							set /A DivisorDecimalStopNum=0

							FOR /L %%Z IN (2,1,10) do (

								if NOT "!SigMaxBusFactor:~%%Z,1!"=="" (

									if "!SigMaxBusFactor:~%%Z,1!"=="0" (
										
										if "!DivisorDecimalStopFlg!"=="false" (
											set /A DivisorDecimalStopNum+=1
										)
									)^
									else (
			
										set "DivisorDecimalStopFlg=true"
									)

									set "IntegerDivisor=!IntegerDivisor!!SigMaxBusFactor:~%%Z,1!"
									set "DivisorDecimalNum=!DivisorDecimalNum!0"
								)
							)

							FOR /L %%Z in (!DivisorDecimalStopNum!,1,!DivisorDecimalStopNum!) do (
								set "IntegerDivisor=!IntegerDivisor:~%%Z!"
							)
							
						)^
						else (
							set "IntegerDivisor=!SigMaxBusFactor!"
						)

						if NOT "!SigMaxBusDividend!"=="!SigMaxBusDividend:.=_!" (

							set "DecimalPointFlg=false"

							FOR /L %%Z IN (0,1,8) do (

								if "!SigMaxBusDividend:~%%Z,1!"=="." (

									set "DecimalPointFlg=true"
								)^
								else if NOT "!SigMaxBusDividend:~%%Z,1!"=="" (

									if "!DecimalPointFlg!"=="true" (

										set "IntegerDivisor=!IntegerDivisor!0"
									)
								)
							)

							set "IntegerDividend=!SigMaxBusDividend:.=!" 
							set /A IntegerDividend=!IntegerDividend!*!DivisorDecimalNum!
						)^
						else (
							set /A IntegerDividend=!SigMaxBusDividend!*!DivisorDecimalNum!
						)

						set /A IntegerDividend=!IntegerDividend!/!IntegerDivisor!

						call:DecToHex !IntegerDividend!
						@REM Signal Max Bus
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_20=!HexValue!"

						@REM tmpDbc_Unit
						set "tmpDbc_Unit=%%Y"
						set "tmpDbc_Unit=!tmpDbc_Unit:"=!"
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_24=!tmpDbc_Unit!"

						@REM Receiver Nodes
						set "tmpDbc_ReciverNodes=%%Z"
						set "tmpDbc_ReciverNodes=!tmpDbc_ReciverNodes: =!"
						
						@REM 该信号只被一个节点接收
						if "!tmpDbc_ReciverNodes!"=="!tmpDbc_ReciverNodes:,=_!" (

							FOR /L %%P in (25,1,!Matrix_TotalColumns!) do (
								if /i "!MatrixData_Row_1_Column_%%P!"=="!tmpDbc_ReciverNodes!" (

									@REM Receiver Node
									set "MatrixData_Row_!Matrix_RowsIndex!_Column_%%P=r"
									set "MatrixData_Row_!Matrix_MsgIndex!_Column_%%P=R"
								)
							)
						)^
						else (
							
							@REM 该信号被多个节点接收
							FOR /L %%P in (25,1,!Matrix_TotalColumns!) do (

								FOR /F "tokens=*" %%O in ("!MatrixData_Row_1_Column_%%P!") DO (
									
									IF NOT "!tmpDbc_ReciverNodes!"=="!tmpDbc_ReciverNodes:%%O=_!" (

										@REM Receiver Node
										set "MatrixData_Row_!Matrix_RowsIndex!_Column_%%P=r"
										set "MatrixData_Row_!Matrix_MsgIndex!_Column_%%P=R"
									)
								)
							)
						)	
					)

					@REM Transmitter Node
					set "MatrixData_Row_!Matrix_RowsIndex!_Column_!Matrix_MsgTransNodeColumn!=s"

					@REM Signal Send Type
					set "MatrixData_Row_!Matrix_RowsIndex!_Column_12=Cyclic"

					set "SignalAndMsgFlg=true"
				)^
				else if NOT "!tmpDbc_RowsData!"=="!tmpDbc_RowsData:BO_=_!" (

					@REM Message
					set /A Matrix_RowsIndex+=1
					set /A Matrix_MsgIndex=!Matrix_RowsIndex!

					@REM 
					set /A Matrix_TotalMsg+=1

					FOR /F "tokens=2-5 delims=: " %%W in ("!tmpDbc_RowsData!") do (

						@REM Msg Name
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_1=%%X"

						@REM Msg Type:TBD
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_2=Normal"

						@REM Msg ID
						call:DecToHex %%W
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_3=!HexValue!"

						@REM Msg Length
						set "MatrixData_Row_!Matrix_RowsIndex!_Column_6=%%Y"

						@REM Transmitter Node
						FOR /L %%V in (25,1,!Matrix_TotalColumns!) do (
							if "!MatrixData_Row_1_Column_%%V!"=="%%Z" (

								@REM Transmitter Node
								set "MatrixData_Row_!Matrix_RowsIndex!_Column_%%V=S"

								@REM 记录发送报文的节点所在的列
								set "Matrix_MsgTransNodeColumn=%%V"
							)
						)	
					)

					@REM Msg Send Type
					set "MatrixData_Row_!Matrix_RowsIndex!_Column_4=Cyclic"
				)^
				else if NOT "!tmpDbc_RowsData!"=="!tmpDbc_RowsData:VAL_TABLE_=_!" (
					set "SignalAndMsgFlg=true"
				)^
				else (
					set "SignalAndMsgFlg=false"
				)		

				@REM 
				set "Matrix_TotalRows=!Matrix_RowsIndex!"
			)^
			else (

				@REM 解析 CM_ SG_\ BA_\ VAL_ 中的报文或信号

				@REM 解析 BA_ 中的报文和信号
				if NOT "!tmpDbc_RowsData!"=="!tmpDbc_RowsData:BA_ =_!" (

					FOR /F "tokens=2-6 delims=; " %%V in ("!tmpDbc_RowsData!") do (

						set "tmpDbc_BaAttriType=%%V"
						set "tmpDbc_BaObjType=%%W"
						set "tmpDbc_BaMsgId=%%X"
						set "tmpDbc_BaAttriVal=%%Y"
						set "tmpDbc_BaSigAttriVal=%%Z"

						if NOT "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:GenSig=_!" (

							if NOT "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:GenSigSendType=_!" (

								set /A tmpDbc_BaSigSendTypeIndex+=1

								set "tmpDbc_BaSigSendType_SigName_!tmpDbc_BaSigSendTypeIndex!=!tmpDbc_BaAttriVal!"
								set "tmpDbc_BaSigSendType_Data_!tmpDbc_BaSigSendTypeIndex!=!tmpDbc_BaSigAttriVal!"
							)^
							else if NOT "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:GenSigStartValue=_!" (
								
								set /A tmpDbc_BaSigStartValueIndex+=1

								call:DecToHex !tmpDbc_BaSigAttriVal!

								set "tmpDbc_BaSigStartValue_SigName_!tmpDbc_BaSigStartValueIndex!=!tmpDbc_BaAttriVal!"
								set "tmpDbc_BaSigStartValue_Data_!tmpDbc_BaSigStartValueIndex!=!HexValue!"
							)
						)^
						else if NOT "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:GenMsg=_!" (

							@REM 
							call:DecToHex !tmpDbc_BaMsgId!
							set tmpDbc_BaMsgId=!HexValue!

							if NOT "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:GenMsgCycleTime=_!" (

								@REM Msg Cycle Time
								if "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:GenMsgCycleTimeFast=_!" (
									
									set /A tmpDbc_BaMsgCycleTimeIndex+=1

									set "tmpDbc_BaMsgCycleTime_MsgId_!tmpDbc_BaMsgCycleTimeIndex!=!tmpDbc_BaMsgId!"
									set "tmpDbc_BaMsgCycleTime_Data_!tmpDbc_BaMsgCycleTimeIndex!=!tmpDbc_BaAttriVal!"
								)^
								else (

									@REM Msg Cycle Time Fast
									set /a tmpDbc_BaMsgCycleTimeFastIndex+=1

									set "tmpDbc_BaMsgCycleTimeFast_MsgId_!tmpDbc_BaMsgCycleTimeFastIndex!=!tmpDbc_BaMsgId!"
									set "tmpDbc_BaMsgCycleTimeFast_Data_!tmpDbc_BaMsgCycleTimeFastIndex!=!tmpDbc_BaAttriVal!"
								)
							)^
							else if NOT "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:GenMsgSendType=_!" (

								@REM Msg Send Type
								set /a tmpDbc_BaMsgSendTypeIndex+=1

								set "tmpDbc_BaMsgSendType_MsgId_!tmpDbc_BaMsgSendTypeIndex!=!tmpDbc_BaMsgId!"
								set "tmpDbc_BaMsgSendType_Data_!tmpDbc_BaMsgSendTypeIndex!=!tmpDbc_BaAttriVal!"
							)^
							else if NOT "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:GenMsgDelayTime=_!" (

								@REM Msg Delay Time
								set /a tmpDbc_BaMsgDelayTimeIndex+=1

								set "tmpDbc_BaMsgDelayTime_MsgId_!tmpDbc_BaMsgDelayTimeIndex!=!tmpDbc_BaMsgId!"
								set "tmpDbc_BaMsgDelayTime_Data_!tmpDbc_BaMsgDelayTimeIndex!=!tmpDbc_BaAttriVal!"
							)^
							else if NOT "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:GenMsgNrOfRepetition=_!" (

								set /a tmpDbc_BaMsgRepetitionIndex+=1

								set "tmpDbc_BaMsgRepetition_MsgId_!tmpDbc_BaMsgRepetitionIndex!=!tmpDbc_BaMsgId!"
								set "tmpDbc_BaMsgRepetition_Data_!tmpDbc_BaMsgRepetitionIndex!=!tmpDbc_BaAttriVal!"
							)
						)^
						else (
							
							@REM 
							if NOT "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:NmBaseAddress=_!" (
								set "tmpDbc_BaNmBaseAddress=!tmpDbc_BaObjType!"
							)^
							else if NOT "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:NmStationAddress=_!" (

								@REM Msg Type
								set /a tmpDbc_NmMsgIndex+=1

								set /A tmpDbc_BaNmAddress=!tmpDbc_BaAttriVal!+!tmpDbc_BaNmBaseAddress!

								call:DecToHex !tmpDbc_BaNmAddress!

								set "tmpDbc_NmMsgIndex_MsgId_!tmpDbc_NmMsgIndex!=!HexValue!"
								set "tmpDbc_NmMsgIndex_Data_!tmpDbc_NmMsgIndex!=NM"
							)^
							else if NOT "!tmpDbc_BaAttriType!"=="!tmpDbc_BaAttriType:DiagState=_!" (

								@REM Msg Type
								set /a tmpDbc_DiagMsgIndex+=1

								set /A tmpDbc_BaDiagAddress=!tmpDbc_BaMsgId!
								call:DecToHex !tmpDbc_BaDiagAddress!

								set "tmpDbc_DiagMsg_MsgId_!tmpDbc_DiagMsgIndex!=!HexValue!"
								set "tmpDbc_DiagMsg_Data_!tmpDbc_DiagMsgIndex!=Diag"
							)
						)
					)
				)^
				else if NOT "!tmpDbc_RowsData!"=="!tmpDbc_RowsData:VAL_=_!" (

					@REM Signal Value Description
					SET /A tmpDbc_ValDescIndex+=1

					FOR /F "tokens=3-4* delims= " %%X in ("!tmpDbc_RowsData!") do (
						
						set "tmpDbc_ValTableSigName=%%X"
						set /A tmpDbc_TotalVal=%%Y
						set "tmpDbc_ValTableDesc=%%Y %%Z"
					)

					SET "tmpDbc_ValTab_SigName_!tmpDbc_ValDescIndex!=!tmpDbc_ValTableSigName!"
					SET "tmpDbc_ValTab_TotalVal_!tmpDbc_ValDescIndex!=!tmpDbc_TotalVal!"
					SET "tmpDbc_ValTab_ValDesc_!tmpDbc_ValDescIndex!=!tmpDbc_ValTableDesc!"
				)^
				else if NOT "!tmpDbc_RowsData!"=="!tmpDbc_RowsData:CM_ SG_=_!" (

					SET /A tmpDbc_CmSgIndex+=1

					FOR /F "tokens=4* delims= " %%Y in ("!tmpDbc_RowsData!") do (

						@REM Signal Description
						set "tmpDbc_CmSg_SigName_!tmpDbc_CmSgIndex!=%%Y"

						set "tmpDbc_CmSgSigDesc=%%Z"
						set "tmpDbc_CmSgSigDesc=!tmpDbc_CmSgSigDesc:"=!"
						set "tmpDbc_CmSgSigDesc=!tmpDbc_CmSgSigDesc:;=!"

						if "!tmpDbc_CmSgSigDesc:~-1!"==" " (
							set "tmpDbc_CmSgSigDesc=!tmpDbc_CmSgSigDesc:~0,-1!"
						)

						set "tmpDbc_CmSg_Data_!tmpDbc_CmSgIndex!=!tmpDbc_CmSgSigDesc!"
					)
				)			
			)
		)
	)

	FOR /L %%Z IN (2,1,!Matrix_TotalRows!) DO (

		@REM 信号

		IF "!MatrixData_Row_%%Z_Column_1!"=="" (

			@REM Signal Send Type
			IF NOT !tmpDbc_BaSigSendTypeStopIndex! EQU !tmpDbc_BaSigSendTypeIndex! (

				FOR /L %%Y IN (1,1,!tmpDbc_BaSigSendTypeIndex!) DO (

					IF "!MatrixData_Row_%%Z_Column_7!"=="!tmpDbc_BaSigSendType_SigName_%%Y!" (

						@REM 
						SET /A tmpDbc_BaSigSendTypeStopIndex+=1

						@REM Signal Send Type
						if "!tmpDbc_BaSigSendType_Data_%%Y!"=="1" (
							set "MatrixData_Row_%%Z_Column_12=OnWrite"
						)^
						else if "!tmpDbc_BaSigSendType_Data_%%Y!"=="2" (
							set "MatrixData_Row_%%Z_Column_12=OnWriteWithRepetition"
						)^
						else if "!tmpDbc_BaSigSendType_Data_%%Y!"=="3" (
							set "MatrixData_Row_%%Z_Column_12=OnChange"
						)^
						else if "!tmpDbc_BaSigSendType_Data_%%Y!"=="4" (
							set "MatrixData_Row_%%Z_Column_12=OnChangeWithRepetition"
						)^
						else if "!tmpDbc_BaSigSendType_Data_%%Y!"=="5" (
							set "MatrixData_Row_%%Z_Column_12=IfActive"
						)^
						else if "!tmpDbc_BaSigSendType_Data_%%Y!"=="6" (
							set "MatrixData_Row_%%Z_Column_12=IfActiveWithRepetition"
						)^
						else if "!tmpDbc_BaSigSendType_Data_%%Y!"=="7" (
							set "MatrixData_Row_%%Z_Column_12=NoSigSendType"
						)
					)
				)
			)

			@REM Initial Value
			IF NOT !tmpDbc_BaSigStartValueStopIndex! EQU !tmpDbc_BaSigStartValueIndex! (
				
				FOR /L %%Y IN (1,1,!tmpDbc_BaSigStartValueIndex!) DO (

					IF "!MatrixData_Row_%%Z_Column_7!"=="!tmpDbc_BaSigStartValue_SigName_%%Y!" (

						@REM Initial Value
						set "MatrixData_Row_%%Z_Column_21=!tmpDbc_BaSigStartValue_Data_%%Y!"

						SET /A tmpDbc_BaSigStartValueStopIndex+=1
					)
				)
			)

			@REM Signal Description
			IF NOT !tmpDbc_CmSgStopIndex! EQU !tmpDbc_CmSgIndex! (

				FOR /L %%Y IN (1,1,!tmpDbc_CmSgIndex!) DO (

					IF "!MatrixData_Row_%%Z_Column_7!"=="!tmpDbc_CmSg_SigName_%%Y!" (

						@REM Signal Description
						set "MatrixData_Row_%%Z_Column_8=!tmpDbc_CmSg_Data_%%Y!"

						SET /A tmpDbc_CmSgStopIndex+=1
					)
				)
			)

			@REM Signal Value Description
			IF NOT !tmpDbc_ValDescStopIndex! EQU !tmpDbc_ValDescIndex! (

				FOR /L %%Y IN (1,1,!tmpDbc_ValDescIndex!) DO (

					IF "!MatrixData_Row_%%Z_Column_7!"=="!tmpDbc_ValTab_SigName_%%Y!" (
						
						SET /A tmpDbc_ValDescStopIndex+=1

						set /A ValDescIndex+=1
						set "Matrix_ValDescRow_!ValDescIndex!=%%Z"
						set "Matrix_ValDescAddLine_!ValDescIndex!=!tmpDbc_ValTab_TotalVal_%%Y!"

						set "tmpDbc_ValTab_ValDesc=!tmpDbc_ValTab_ValDesc_%%Y!"
						set "tmpDbc_ValTab_ValDesc=!tmpDbc_ValTab_ValDesc:"=`!"

						FOR /L %%X in (!tmpDbc_ValTab_TotalVal_%%Y!,-1,0) do (

							FOR /F "tokens=2* delims=;`" %%V in ("!tmpDbc_ValTab_ValDesc!") do (
								
								@REM 
								call:DecToHex %%X

								set "tmpDbc_%%Z_ValDesc_%%X=!HexValue!:%%V"

								if %%X NEQ 0 (

									set "tmpDbc_ValTab_ValDesc=%%W"
								)
							)
						)
					)
				)
			)
		)^
		ELSE (

			@REM 报文
			
			@REM Msg Cycle Time
			IF NOT !tmpDbc_BaMsgCycleTimeStopIndex! EQU !tmpDbc_BaMsgCycleTimeIndex! (

				FOR /L %%Y IN (1,1,!tmpDbc_BaMsgCycleTimeIndex!) DO (

					IF "!MatrixData_Row_%%Z_Column_3!"=="!tmpDbc_BaMsgCycleTime_MsgId_%%Y!" (

						@REM Msg Cycle Time
						set "MatrixData_Row_%%Z_Column_5=!tmpDbc_BaMsgCycleTime_Data_%%Y!"

						SET /A tmpDbc_BaMsgCycleTimeStopIndex+=1
					)
				)
			)

			@REM Msg Cycle Time Fast
			IF NOT !tmpDbc_BaMsgCycleTimeFastStopIndex! EQU !tmpDbc_BaMsgCycleTimeFastIndex! (

				FOR /L %%Y IN (1,1,!tmpDbc_BaMsgCycleTimeFastIndex!) DO (

					IF "!MatrixData_Row_%%Z_Column_3!"=="!tmpDbc_BaMsgCycleTimeFast_MsgId_%%Y!" (

						@REM Msg Cycle Time Fast
						set "MatrixData_Row_%%Z_Column_26=!tmpDbc_BaMsgCycleTimeFast_Data_%%Y!"

						SET /A tmpDbc_BaMsgCycleTimeFastStopIndex+=1
					)
				)
			)

			@REM Msg Send Type
			IF NOT !tmpDbc_BaMsgSendTypeStopIndex! EQU !tmpDbc_BaMsgSendTypeIndex! (

				FOR /L %%Y IN (1,1,!tmpDbc_BaMsgSendTypeIndex!) DO (

					IF "!MatrixData_Row_%%Z_Column_3!"=="!tmpDbc_BaMsgSendType_MsgId_%%Y!" (

						@REM Msg Send Type
						if "!tmpDbc_BaMsgSendType_Data_%%Y!"=="1" (
							set "MatrixData_Row_%%Z_Column_4=IfActive"
						)^
						else if "!tmpDbc_BaMsgSendType_Data_%%Y!"=="2" (
							set "MatrixData_Row_%%Z_Column_4=Event"
						)^
						else if "!tmpDbc_BaMsgSendType_Data_%%Y!"=="3" (
							set "MatrixData_Row_%%Z_Column_4=CA"
						)^
						else if "!tmpDbc_BaMsgSendType_Data_%%Y!"=="4" (
							set "MatrixData_Row_%%Z_Column_4=CE"
						)^
						else if "!tmpDbc_BaMsgSendType_Data_%%Y!"=="5" (
							set "MatrixData_Row_%%Z_Column_4=NoMsgSendType"
						)

						SET /A tmpDbc_BaMsgSendTypeStopIndex+=1
					)
				)
			)

			@REM Msg Delay Time
			IF NOT !tmpDbc_BaMsgDelayTimeStopIndex! EQU !tmpDbc_BaMsgDelayTimeIndex! (

				FOR /L %%Y IN (1,1,!tmpDbc_BaMsgDelayTimeIndex!) DO (

					IF "!MatrixData_Row_%%Z_Column_3!"=="!tmpDbc_BaMsgDelayTime_MsgId_%%Y!" (

						@REM Msg Delay Time
						set "MatrixData_Row_%%Z_Column_28=!tmpDbc_BaMsgDelayTime_Data_%%Y!"

						SET /A tmpDbc_BaMsgDelayTimeStopIndex+=1
					)
				)
			)

			@REM Msg repetitions
			IF NOT !tmpDbc_BaMsgRepetitionStopIndex! EQU !tmpDbc_BaMsgRepetitionIndex! (

				FOR /L %%Y IN (1,1,!tmpDbc_BaMsgRepetitionIndex!) DO (

					IF "!MatrixData_Row_%%Z_Column_3!"=="!tmpDbc_BaMsgRepetition_MsgId_%%Y!" (

						@REM Msg repetitions
						set "MatrixData_Row_%%Z_Column_27=!tmpDbc_BaMsgRepetition_Data_%%Y!"

						SET /A tmpDbc_BaMsgRepetitionStopIndex+=1
					)
				)
			)

			@REM Msg Type : NM
			IF NOT !tmpDbc_NmMsgStopIndex! EQU !tmpDbc_NmMsgIndex! (

				FOR /L %%Y IN (1,1,!tmpDbc_NmMsgIndex!) DO (

					IF "!MatrixData_Row_%%Z_Column_3!"=="!tmpDbc_NmMsgIndex_MsgId_%%Y!" (

						@REM Msg Type
						set "MatrixData_Row_%%Z_Column_2=!tmpDbc_NmMsgIndex_Data_%%Y!"

						SET /A tmpDbc_NmMsgStopIndex+=1
					)
				)
			)

			@REM Msg Type : Diag
			IF NOT !tmpDbc_DiagMsgStopIndex! EQU !tmpDbc_DiagMsgIndex! (

				FOR /L %%Y IN (1,1,!tmpDbc_DiagMsgIndex!) DO (

					IF "!MatrixData_Row_%%Z_Column_3!"=="!tmpDbc_DiagMsg_MsgId_%%Y!" (

						@REM Msg Type
						set "MatrixData_Row_%%Z_Column_2=!tmpDbc_DiagMsg_Data_%%Y!"

						SET /A tmpDbc_DiagMsgStopIndex+=1
					)
				)
			)
		)
	)

	@REM 解析信号值描述并输出信号和报文
	set /A ValDescStartIndex=1
	FOR /L %%Z in (1,1,!Matrix_TotalRows!) do (

		@REM 
		set "MatrixData="

		if "!MatrixData_Row_%%Z_Column_1!"=="" (

			@REM 
			set "ValDescBlankFlg=true"

			FOR /L %%Y in (!ValDescStartIndex!,1,!ValDescIndex!) do (

				if "!Matrix_ValDescRow_%%Y!"=="%%Z" (

					@REM 
					FOR /L %%X in (!Matrix_ValDescRow_%%Y!,1,!Matrix_ValDescRow_%%Y!) do (

						@REM 
						if !Matrix_ValDescAddLine_%%Y! GTR 1 (

							@REM Signal Value Description 1
							set "MatrixData_Row_%%Z_Column_25="!tmpDbc_%%Z_ValDesc_0!"

							@REM 
							FOR /L %%W in (1,1,25) do (

								set "MatrixData=!MatrixData!,!MatrixData_Row_%%Z_Column_%%W!"
							)

							@REM 消除第一个空列
							set "MatrixData=!MatrixData:~1!"
							echo !MatrixData!>> !outputFile!

							set "ValDescKeyLast="
							set "ValDescValueLast="
							set "MatrixDataLast="
							set "ValDescSameFlg=false"
							set "MatrixValDescEndFlg=false"
							
							FOR /L %%W IN (1,1,!Matrix_ValDescAddLine_%%Y!) DO (

								FOR /F "tokens=1,2 delims=:" %%U IN ("!tmpDbc_%%Z_ValDesc_%%W!") do (
									set "ValDescKey=%%U"
									set "ValDescValue=%%V"
								)

								if "!ValDescValue!"=="!ValDescValueLast!" (

									@REM 
									if "!ValDescSameFlg!"=="false" (
										
										set "MatrixDataLast="
										set "ValDescSameFlg=true"

										@REM 
										set "MatrixDataLast=!ValDescKeyLast!"
									)

									if "%%W"=="!Matrix_ValDescAddLine_%%Y!" (

										@REM 
										set "MatrixDataLast=!MatrixDataLast!-!ValDescKey!:!ValDescValueLast!"

										set "MatrixValDescEndFlg=true"
									)
								)^
								else (

									if "!ValDescSameFlg!"=="true" (

										@REM 
										set "MatrixDataLast=!MatrixDataLast!-!ValDescKeyLast!:!ValDescValueLast!"
										echo !MatrixDataLast!>> !outputFile!
					
										set "ValDescSameFlg=false"
									)^
									else (

										@REM 
										set "MatrixData=!ValDescKeyLast!:!ValDescValueLast!"

										if NOT "!ValDescKeyLast!"=="" (

											echo !MatrixData!>> !outputFile!
										)
									)
								)

								set "ValDescKeyLast=!ValDescKey!"
								set "ValDescValueLast=!ValDescValue!"
							)

							@REM 
							if "!MatrixValDescEndFlg!"=="false" (

								@REM Signal Value Description N
								FOR /L %%W IN (!Matrix_ValDescAddLine_%%Y!,1,!Matrix_ValDescAddLine_%%Y!) DO (
								
									set "MatrixData_Row_%%Z_Column_25=!tmpDbc_%%Z_ValDesc_%%W!""
								)
							)^
							else (

								set "MatrixData_Row_%%Z_Column_25=!MatrixDataLast!""
							)

							set "MatrixData="

							FOR /L %%W in (25,1,!Matrix_TotalColumns!) do (

								set "MatrixData=!MatrixData!,!MatrixData_Row_%%Z_Column_%%W!"
							)

							@REM 消除第一个空列
							set "MatrixData=!MatrixData:~1!"
							echo !MatrixData!>> !outputFile!

						)^
						else if !Matrix_ValDescAddLine_%%Y! EQU 1 (

							@REM Signal Value Description 1
							set "MatrixData_Row_%%Z_Column_25="!tmpDbc_%%Z_ValDesc_0!"

							@REM 
							FOR /L %%W in (1,1,25) do (

								set "MatrixData=!MatrixData!,!MatrixData_Row_%%Z_Column_%%W!"
							)

							@REM 消除第一个空列
							set "MatrixData=!MatrixData:~1!"
							echo !MatrixData!>> !outputFile!

							@REM Signal Value Description 2
							set "MatrixData_Row_%%Z_Column_25=!tmpDbc_%%Z_ValDesc_1!""

							set "MatrixData="

							FOR /L %%W in (25,1,!Matrix_TotalColumns!) do (

								set "MatrixData=!MatrixData!,!MatrixData_Row_%%Z_Column_%%W!"
							)

							@REM 消除第一个空列
							set "MatrixData=!MatrixData:~1!"
							echo !MatrixData!>> !outputFile!
						)^
						else if !Matrix_ValDescAddLine_%%Y! EQU 0 (

							@REM Signal Value Description
							set "MatrixData_Row_%%Z_Column_25=!tmpDbc_%%Z_ValDesc_0!"

							@REM 
							FOR /L %%W in (1,1,!Matrix_TotalColumns!) do (

								set "MatrixData=!MatrixData!,!MatrixData_Row_%%Z_Column_%%W!"
							)

							@REM 消除第一个空列
							set "MatrixData=!MatrixData:~1!"
							echo !MatrixData!>> !outputFile!
						)
					)

					@REM 
					set /A ValDescStartIndex+=1

					@REM 
					set "ValDescBlankFlg=false"
				)
			)

			@REM 
			if "!ValDescBlankFlg!"=="true" (

				@REM Signal Value Description
				set "MatrixData_Row_%%Z_Column_25="

				@REM 
				FOR /L %%Y in (1,1,!Matrix_TotalColumns!) do (

					set "MatrixData=!MatrixData!,!MatrixData_Row_%%Z_Column_%%Y!"
				)

				@REM 消除第一个空列
				set "MatrixData=!MatrixData:~1!"
				echo !MatrixData!>> !outputFile!
			)

		)^
		else (
			
			@REM 
			FOR /L %%Y in (1,1,!Matrix_TotalColumns!) do (

				set "MatrixData=!MatrixData!,!MatrixData_Row_%%Z_Column_%%Y!"
			)

			@REM 消除第一个空列
			set "MatrixData=!MatrixData:~1!"
			echo !MatrixData!>> !outputFile!
		)
	)

	@REM 将 Csv 文件转换为 xlsx 文件
	set "CsvToXlsFile=!outputFile!"
	if exist !outputFile! (
		goto CsvToXls
	)

	call:XlsFileConversion

	set "ConversionSuccessFlg=true"

	goto EndConversion

@REM ================================================================================================
@REM ====================================   End: DBC Conversion  ====================================
@REM ================================================================================================


@REM ================================================================================================
@REM ===================================   Start: CSV Conversion  ===================================
@REM ================================================================================================

@REM convert *.csv file to *.dbc file
:Csv_To_Dbc

    @REM conversion output file
	set outputFile=!onlyNameInputFile!.dbc

	@REM if output file is exist, delete it
	if exist %outputFile% (del %outputFile%)

	@REM save BO_SG section data
	set BO_SG_TempFile=C:\Windows\Temp\Temp_CSVTODBC_BO_SG.txt

	@REM save CM_BU section data
	@REM set CM_BU_TempFile=C:\Windows\Temp\Temp_CSVTODBC_CM_BU.txt

	@REM save CM_BO section data
	@REM set CM_BO_TempFile=C:\Windows\Temp\Temp_CSVTODBC_CM_BO.txt

	@REM save CM_SG section data
	set CM_SG_TempFile=C:\Windows\Temp\Temp_CSVTODBC_CM_SG.txt

	@REM save BA_BU section data
	set BA_BU_TempFile=C:\Windows\Temp\Temp_CSVTODBC_BA_BU.txt

	@REM save BA_BO section data
	set BA_BO_TempFile=C:\Windows\Temp\Temp_CSVTODBC_BA_BO.txt

	@REM save BA_SG section data
	set BA_SG_TempFile=C:\Windows\Temp\Temp_CSVTODBC_BA_SG.txt

	@REM save VAL_SG section data
	set VAL_SG_TempFile=C:\Windows\Temp\Temp_CSVTODBC_VAL_SG.txt

	@REM save VAL_TABLE section data
	set VAL_TABLE_TempFile=C:\Windows\Temp\Temp_CSVTODBC_VAL_TABLE.txt

	@REM save Signal Group section data
	set SIG_GROUP_TempFile=C:\Windows\Temp\Temp_CSVTODBC_SIG_GROUP.txt	

	@REM *.dbc file keyword default configuration
	echo VERSION "">> %outputFile%
	echo, >> %outputFile%
	echo, >> %outputFile%
	echo NS_ :>> %outputFile%
  	echo 	NS_DESC_>> %outputFile%
  	echo 	CM_>> %outputFile%
  	echo 	BA_DEF_>> %outputFile%
  	echo 	BA_>> %outputFile%
  	echo 	VAL_>> %outputFile%
  	echo 	CAT_DEF_>> %outputFile%
  	echo 	CAT_>> %outputFile%
  	echo 	FILTER>> %outputFile%
  	echo 	BA_DEF_DEF_>> %outputFile%
  	echo 	EV_DATA_>> %outputFile%
  	echo 	ENVVAR_DATA_>> %outputFile%
  	echo 	SGTYPE_>> %outputFile%
  	echo 	SGTYPE_VAL_>> %outputFile%
  	echo 	BA_DEF_SGTYPE_>> %outputFile%
  	echo 	BA_SGTYPE_>> %outputFile%
  	echo 	SIG_TYPE_REF_>> %outputFile%
  	echo 	VAL_TABLE_>> %outputFile%
  	echo 	SIG_GROUP_>> %outputFile%
  	echo 	SIG_VALTYPE_>> %outputFile%
  	echo 	SIGTYPE_VALTYPE_>> %outputFile%
  	echo 	BO_TX_BU_>> %outputFile%
  	echo 	BA_DEF_REL_>> %outputFile%
  	echo 	BA_REL_>> %outputFile%
  	echo 	BA_DEF_DEF_REL_>> %outputFile%
  	echo 	BU_SG_REL_>> %outputFile%
  	echo 	BU_EV_REL_>> %outputFile%
  	echo 	BU_BO_REL_>> %outputFile%
  	echo 	SG_MUL_VAL_>> %outputFile%
	echo,  >> %outputFile%
	echo BS_:>> %outputFile%
	echo,  >> %outputFile%
	
	@REM Converted 10%
	echo 				  ^|         Converted to 10%%, Please wait^^!       ^|

	@REM "delimiterNum" is used to record the number of occurrences of a single double quotation mark
	set /A delimiterNum=0

	@REM Number of occurrences of a single double quotation mark modulo 2, record whether the number
	@REM of occurrences of a single double quotation mark is even or odd
    set /A modVal=0

	@REM Save the value of the previous modulus operation
    set /A modValLast=0

	@REM Record the row data obtained from the file
    set "rowsData=" 

	@REM Save the previous row data
    set "rowsDataLast="

	@REM Whether the data in the record row has been organized. If it is completed, 
	@REM it is true. Otherwise, it is false and defaults to true
    set rowsDataSortFinshFlg=true

	@REM The number of messages
	set /A messagesNum=0

	@REM The number of signals
	set /A signalsNum=0

	@REM The number of network management messages
	set /A nmMessageCount=0

	@REM Network management base address
	set /A nmBaseAddress=0

	@REM Diagnostic request tester node
	set "diagReqTesterNode=0x0"

	@REM Obtain a diagnostic request node, such as a node for a functional diagnostic request (0X7DF),
	@REM  through which you can determine whether other diagnostic message are diagnostic responses or physical requests
	set "DiagReqNodeFound=false"

	@REM Stores a list of signals for grouping signals
	set "SIG_GROUP_SignalList="

	@REM 
	set "regStr=a b c d e f"

	@REM Initialize diagnostic nodes to store diagnostic request nodes, 
	@REM such as the sending node corresponding to functional addressing 0x7DF
	for /L %%Z in (1,1,!NetworkNodesNum!) do (
		set /A DiagNode_%%Z=0
	)

	@REM annotation 1:"!fullPathInputFile!"represents the first parameter passed to the batch,%~f0 represents the batch file itself, 
	@REM 			   and the batch will read data from the file represented by!fullPathInputFile!. There are two 
	@REM 			   ways to pass the first parameter to the batch file: 
	@REM 			1. Run the script and file in cmd, such as ..\xx.bat ..\yy.csv, ".." represents the parent path; 
	@REM 			2. Directly drag and drop the file onto the batch file, and the batch process will automatically 
	@REM 			   retrieve the file and perform calculations
    @REM annotation 2:Read the entire line of data from the file for calculation
	for /F "usebackq tokens=*" %%Z in ("!fullPathInputFile!") do (
		
		@REM Store the entire row of data obtained from a file
        set "rowsData=%%Z"

		@REM Replace the """ symbol in the row data with the " \ " symbol to facilitate character replacement later
		@REM Because it is more troublesome to handle the symbol """
		@REM eg: ab"cd"ef -- ab \ cd \ ef
		set "replaceRowsData=!rowsData:"= \ !" 

		@REM Use the "\" symbol to divide the row data into 3 columns, if the data after the column is not empty, 
		@REM it means that the column contains an "\" sign, determine whether all the columns are empty, 
		@REM you can get how much of a row of data contains the "\" sign. The number of X symbols calculated 
		@REM here is the most critical step in data wrangling.
        if NOT "!rowsData!"=="!replaceRowsData!" ( 
			for /F "tokens=2-4 delims=\" %%X in ("!replaceRowsData!") do (
				if NOT "%%X"=="" ( set /A delimiterNum+=1 )
				if NOT "%%Y"=="" ( set /A delimiterNum+=1 )
				if NOT "%%Z"=="" ( set /A delimiterNum+=1 )
			)
		)
        
		@REM Modulo the number of "\" symbols
        set /A modVal=!delimiterNum!%%2

		@REM When the modulus value is "1", it indicates that the original data has been split
		@REM into multiple columns and needs to be concatenated and restored to one column
        if !modVal!==1 ( 

			@REM When the last modulus value "modValLast" is "0", it indicates that 
			@REM the previous row of data is complete. Otherwise,
			@REM it indicates that the previous row of data is incomplete and needs to be concatenated
            if !modValLast!==0 ( 
                set "rowsDataLast=!rowsData!"
            )^
            else ( 
                set "rowsDataLast=!rowsDataLast!`!rowsData!"
            )

			@REM When the modulus value is "1", it indicates that the row data is not complete,
			@REM so the variable "rowsDataSortFinshFlg" equal "false"
            set rowsDataSortFinshFlg=false
        )^
        else (

			@REM If the modulo is even, it means that the x sign is even, the x sign can be matched in pairs, 
			@REM and the row data does not need to be processed
            if !modValLast!==1 ( 
                set "rowsData=!rowsDataLast!`!rowsData!"
                set rowsDataLast="" 
            )

			@REM When the modulus value is "0", it indicates that the row data is complete, 
			@REM so the variable "rowsDataSortFinshFlg" equal "true"
            set rowsDataSortFinshFlg=true
        )
        
		@REM When the row data obtained from the file has been processed and meets the calculation requirements, the calculation begins
        if !rowsDataSortFinshFlg!==true (

			@REM Add a "," symbol to the beginning and end of the row data to ensure that when the column is used later, 
			@REM the columns in the row data will not be merged into a single column
            set "rowsData=,!rowsData!,"

			@REM Use ",NULL," to replace ",," to ensure that multiple empty columns are not merged into one 
			@REM empty column after performing the column splitting operation
            for /L %%Z in (1,1,2) do ( set "rowsData=!rowsData:,,=,NULL,!" )

			@REM 
			set "replaceRowsData=!rowsData:"=\!"

			if NOT "!rowsData!"=="!replaceRowsData!" ( 

				@REM Replace the '"' symbol with the '\' symbol to ensure that the '"' 
				@REM symbol does not cause failures during subsequent data splitting processes
				set "rowsData=!rowsData:"=\!"

				@REM Use the "\" symbol to divide the row data into multiple columns. If the column contains the "," 
				@REM symbol, replace the symbol with "}". This is because in the subsequent data processing process, 
				@REM the "," symbol needs to be used for row data splitting. The "," symbol here will affect the results 
				@REM of subsequent column splitting, so it needs to be replaced with another symbol
				for /F "tokens=1-4* delims=\" %%V in ("!rowsData!") do (
					set "tempV=%%V"
					set "tempW=%%W"
					set "tempX=%%X"
					set "tempY=%%Y"
					set "tempZ=%%Z"

					if NOT "!tempW!"=="" ( set "tempW=!tempW:,=}!" )
					if NOT "!tempY!"=="" ( set "tempY=!tempY:,=}!" )

					@REM Splicing data again
					set "rowsData=!tempV!!tempW!!tempX!!tempY!!tempZ!"
				)
			)

			@REM Use the "," symbol to divide the row data into 42 columns, including 28 columns 
			@REM related to messages and signals, and 14 columns related to nodes
			for /f "tokens=1-25* delims=," %%a in ("!rowsData!") do (
				for /f "tokens=1-17 delims=," %%A in ("%%z") do (	

					@REM save message name
					set "MsgName=%%a"

					@REM log all nodes 
					set NetworkNode_1=%%D
					set NetworkNode_2=%%E
					set NetworkNode_3=%%F
					set NetworkNode_4=%%G
					set NetworkNode_5=%%H
					set NetworkNode_6=%%I
					set NetworkNode_7=%%J
					set NetworkNode_8=%%K
					set NetworkNode_9=%%L
					set NetworkNode_10=%%M
					set NetworkNode_11=%%N
					set NetworkNode_12=%%O
					set NetworkNode_13=%%P
					set NetworkNode_14=%%Q

					@REM 
					set "replacceMsgName=!MsgName:%MsgNameColumn%=_!"

					@REM 
					if "!MsgName!"=="!replacceMsgName!" ( set "foundMsgFlg=false" ) else ( set "foundMsgFlg=true" )
					 
					if !MsgName!==NULL (
						@REM obtain signals

						@REM log the number of signals
						set /A signalsNum+=1

						@REM obtain signal byte order, value type, unit
						set "SG_ByteOrder_ColumnData=%%i"
						set "SG_ValueType_ColumnData=%%n"
						set "SG_Unit_ColumnData=%%x"

						if /i !SG_ByteOrder_ColumnData!==Intel ( set "SG_ByteOrder=1" ) else ( set "SG_ByteOrder=0" )
						if /i !SG_ValueType_ColumnData!==Unsigned ( set "SG_ValueType=+" ) else ( set "SG_ValueType=-" )
						if /i !SG_Unit_ColumnData!==NULL ( set "SG_Unit=" ) else ( set "SG_Unit=!SG_Unit_ColumnData!" )

						@REM Determine which nodes are receiving the signal
						for /L %%Z in (1,1,!NetworkNodesNum!) do ( 
							if /i "!NetworkNode_%%Z!"=="r" ( set "receiverNode_%%Z=!BU_NetworkNode_%%Z!" ) else ( set "receiverNode_%%Z=" )
						)

						@REM Splicing all receiving nodes
						set "receiverNodes="
						for /L %%Z in (1,1,!NetworkNodesNum!) do (
							set "receiverNodes=!receiverNodes!,!receiverNode_%%Z!"
						)
						
						@REM Replace two or more adjacent ',' symbols with one ','
						for /L %%V in (1,1,8) do ( set "receiverNodes=!receiverNodes:,,=,!" )

						@REM Eliminate the last redundant "," symbol, for example, if the original 
						@REM node is: node1, node2, then the eliminated node is: node1, node2
						set receiverNode_LastSign=!receiverNodes:~-1!
						if "!receiverNode_LastSign!"=="," ( set "receiverNodes=!receiverNodes:~0,-1!" )

						@REM Eliminate the first redundant "," symbol, for example, if the original 
						@REM node is: ,node1, node2 then the eliminated node is: node1, node2
						set receiverNode_FirstSign=!receiverNodes:~0,1!
						if "!receiverNode_FirstSign!"=="," ( set "receiverNodes=!receiverNodes:~1!" )

						@REM If there are no receiving nodes, keep the receiver nodes default "Vector__XXX"
						if "!receiverNodes!"=="" ( set "receiverNodes=Vector__XXX" ) else ( set "receiverNodes= !receiverNodes!" )
						
						@REM obtain signal name
						set "SG_SignalName=%%g"
						set "SG_SignalName=!SG_SignalName: =!"

						@REM obtain signal start bit
						set "SG_StartBit=%%k"

						@REM signal length
						set "SG_SignalLength=%%m"
						
						@REM signal factor
						set "SG_SignalFactor=%%o"

						@REM signal offset
						set "SG_SignalOffset=%%p"

						@REM signal min value
						set "SG_SignalMinValue=%%q"

						@REM signal max value
						set "SG_SignalMaxValue=%%r"

						@REM Signal format: SG_ SignalName : StartBit|SignalSize@tmpDbc_ByteOrder ValueType (Factor,Offset) [Min|Max] tmpDbc_Unit Receiver
						set "SG_Signal=SG_ !SG_SignalName! : !SG_StartBit!^|!SG_SignalLength!@!SG_ByteOrder!!SG_ValueType! ^(!SG_SignalFactor!,!SG_SignalOffset!^) [!SG_SignalMinValue!^|!SG_SignalMaxValue!] "!SG_Unit!" !receiverNodes! "
						
						@REM save signal data to BO_SG_TempFile file
						echo  !SG_Signal! >> %BO_SG_TempFile%

						@REM signal description
						set "SG_SignalDescription=%%h"
						if NOT "!SG_SignalDescription!"=="NULL" (

							set "SG_SignalDescription=!SG_SignalDescription:}=,!"
							set "SG_SignalDescription=!SG_SignalDescription:`= !"

							set "SG_SigDescIncludeQuotes=!SG_SignalDescription:"=_!"

							@REM save signal comment to CM_SG_TempFile file
							if "!SG_SignalDescription!"=="!SG_SigDescIncludeQuotes!" ( 
								set "CM_SG_Signal=!CM_SG_MsgId! !SG_SignalName! "!SG_SignalDescription!"^;" 
							)^
							else ( 
								set "CM_SG_Signal=!CM_SG_MsgId! !SG_SignalName! !SG_SignalDescription!^;" 
							) 

							echo !CM_SG_Signal! >> %CM_SG_TempFile%
						)

						@REM BA_ SG signal initial value
						set /A BA_SG_InitialValue=%%u

						@REM BA_SG signal send type
						set "BA_SG_SendType=%%l"

						@REM BA_ SG signal initial value
						if NOT "!BA_SG_InitialValue!"=="0" (
							set "BA_SG_GenSigStartValue=BA_ "GenSigStartValue" SG_ !BO_MessageId! !SG_SignalName! !BA_SG_InitialValue!;"
							echo !BA_SG_GenSigStartValue! >> %BA_SG_TempFile%
						)

						@REM judge signal send type
						@REM send type:"Cyclic","OnWrite","OnWriteWithRepetition","OnChange","OnChangeWithRepetition","IfActive","IfActiveWithRepetition","NoSigSendType";
						if "!BA_SG_SendType!"=="OnWrite" (
							set "BA_SG_GenSigSendType=BA_ "GenSigSendType" SG_ !BO_MessageId! !SG_SignalName! 1;"
							echo !BA_SG_GenSigSendType! >> %BA_SG_TempFile%
						)^
						else if "!BA_SG_SendType!"=="OnWriteWithRepetition" (
							set "BA_SG_GenSigSendType=BA_ "GenSigSendType" SG_ !BO_MessageId! !SG_SignalName! 2;"
							echo !BA_SG_GenSigSendType! >> %BA_SG_TempFile%
						)^
						else if "!BA_SG_SendType!"=="OnChange" (
							set "BA_SG_GenSigSendType=BA_ "GenSigSendType" SG_ !BO_MessageId! !SG_SignalName! 3;"
							echo !BA_SG_GenSigSendType! >> %BA_SG_TempFile%
						)^
						else if "!BA_SG_SendType!"=="OnChangeWithRepetition" (
							set "BA_SG_GenSigSendType=BA_ "GenSigSendType" SG_ !BO_MessageId! !SG_SignalName! 4;"
							echo !BA_SG_GenSigSendType! >> %BA_SG_TempFile%
						)^
						else if "!BA_SG_SendType!"=="IfActive" (
							set "BA_SG_GenSigSendType=BA_ "GenSigSendType" SG_ !BO_MessageId! !SG_SignalName! 5;"
							echo !BA_SG_GenSigSendType! >> %BA_SG_TempFile%
						)^
						else if "!BA_SG_SendType!"=="IfActiveWithRepetition" (
							set "BA_SG_GenSigSendType=BA_ "GenSigSendType" SG_ !BO_MessageId! !SG_SignalName! 6;"
							echo !BA_SG_GenSigSendType! >> %BA_SG_TempFile%
						)^
						else if "!BA_SG_SendType!"=="NoSigSendType" (
							set "BA_SG_GenSigSendType=BA_ "GenSigSendType" SG_ !BO_MessageId! !SG_SignalName! 7;"
							echo !BA_SG_GenSigSendType! >> %BA_SG_TempFile%
						)^
						else (
							echo, > nul
						)

						@REM VAL_ Signal Value Description
						set "VAL_SignalValueDescription=%%y"

						@REM Determine if the signal description is empty
						if NOT "!VAL_SignalValueDescription!"=="NULL" (

							@REM Split the signal column data into 25 columns to ensure that it can handle 25 rows of signal values
							for /F "tokens=1-25* delims=`" %%a in ("!VAL_SignalValueDescription!") do (

								@REM Record the split signal value description data for each row
								set "VAL_SG_1=%%a"
								set "VAL_SG_2=%%b"
								set "VAL_SG_3=%%c"
								set "VAL_SG_4=%%d"
								set "VAL_SG_5=%%e"
								set "VAL_SG_6=%%f"
								set "VAL_SG_7=%%g"
								set "VAL_SG_8=%%h"
								set "VAL_SG_9=%%i"
								set "VAL_SG_10=%%j"
								set "VAL_SG_11=%%k"
								set "VAL_SG_12=%%l"
								set "VAL_SG_13=%%m"
								set "VAL_SG_14=%%n"
								set "VAL_SG_15=%%o"
								set "VAL_SG_16=%%p"
								set "VAL_SG_17=%%q"
								set "VAL_SG_18=%%r"
								set "VAL_SG_19=%%s"
								set "VAL_SG_20=%%t"
								set "VAL_SG_21=%%u"
								set "VAL_SG_22=%%v"
								set "VAL_SG_23=%%w"
								set "VAL_SG_24=%%x"
								set "VAL_SG_25=%%y"
								set "VAL_SG_26=%%z"

								@REM Initialize List
								set "VAL_SG=VAL_ "
								set "VAL_SG_List="

								@REM Starting from the last line, determine if the data is empty because VAL_ It is sorted from the 
								@REM maximum value to the minimum, and generally speaking, the larger the signal value, 
								@REM the lower the row, so it is necessary to start judging from the last row of data
								for /L %%Z in (26,-1,1) do (

									@REM Obtain data for each row after column splitting
									set "VAL_SG_Object=!VAL_SG_%%Z!"
					
									@REM The data is empty and no action will be taken
									if NOT "!VAL_SG_Object!"=="" (

										@REM To obtain the first five characters of data, such as 0x123456, the obtained characters should be: 0x123
										set "VAL_SG_temp1=!VAL_SG_Object:~0,7!"
										
										@REM 
										set "VAL_SG_ProcessFlg=false"
										for /F "tokens=2 delims=~-" %%Z in ("!VAL_SG_temp1!") do (
											if NOT "%%Z"=="" ( set "VAL_SG_ProcessFlg=true" )
										)

										@REM Determine whether the obtained data contains the character '~ -'. If it does, 
										@REM it indicates that the data needs special processing, such as "0x12-0x34 Valid", and the data needs to be processed
										if "!VAL_SG_ProcessFlg!"=="true" ( 

											@REM When processing such data "0x01~0x10:Valid  0x11:Invalid", it is necessary to divide the data into three columns using the "~" symbol
											for /F "tokens=1-2* delims=~-" %%W in ("!VAL_SG_Object!") do (

												@REM save such data "0x10:Valid"
												set "VAL_SG_List_X="

												@REM save such data "0x11:Invalid"
												set "VAL_SG_List_Y="

												@REM 
												set "VAL_SG_ObjectX=%%X"

												@REM 
												for /F "tokens=1-2 delims= " %%Y in ("!VAL_SG_ObjectX!") do (
													set "VAL_SG_ObjectX_Column1=%%Y"
													set "VAL_SG_ObjectX_Column2=%%Z"

													if "!VAL_SG_ObjectX_Column2!"=="!VAL_SG_ObjectX_Column2:0x=_!" (
														set "VAL_SG_ObjectX_Column1=!VAL_SG_ObjectX_Column1!!VAL_SG_ObjectX_Column2!"
													)
												)

												@REM 
												set VAL_SG_Number_X_Column1=!VAL_SG_ObjectX_Column1:~3,1!

												@REM 
												set "VAL_SG_ObjectW=%%W"
												set VAL_SG_Number_W=!VAL_SG_ObjectW:~3,1!

												@REM Determine whether the data is empty
												if NOT "!VAL_SG_ObjectX_Column2!"=="" (

													@REM Determine if the data contains "xx", if so, it needs to be processed, otherwise nothing will be done
													if NOT "!VAL_SG_ObjectX_Column2!"=="!VAL_SG_ObjectX_Column2:0x=_!" ( 

														@REM Gets the fourth value of the data, if the value belongs to "0 1 2 3 4 5 6 7 8 9 A b c d e f", 
														@REM for example, if the data is "0x11", the data is treated as a two-digit hexadecimal number, 
														@REM otherwise the data is treated as a single-digit hexadecimal number
														set VAL_SG_Number_X_Column2=!VAL_SG_ObjectX_Column2:~3,1!

														@REM 
														set "VAL_SG_X_Column2_TwoDigitHex=false"
														for /L %%Z in (0,1,9) do (
															if /i "!VAL_SG_Number_X_Column2!"=="%%Z" ( set "VAL_SG_X_Column2_TwoDigitHex=true" )
														)

														for /f "tokens=1-6 delims= " %%U in ("!regStr!") do (
															if /i "!VAL_SG_Number_X_Column2!"=="%%U" ( set "VAL_SG_X_Column2_TwoDigitHex=true" )
															if /i "!VAL_SG_Number_X_Column2!"=="%%V" ( set "VAL_SG_X_Column2_TwoDigitHex=true" )
															if /i "!VAL_SG_Number_X_Column2!"=="%%W" ( set "VAL_SG_X_Column2_TwoDigitHex=true" )
															if /i "!VAL_SG_Number_X_Column2!"=="%%X" ( set "VAL_SG_X_Column2_TwoDigitHex=true" )
															if /i "!VAL_SG_Number_X_Column2!"=="%%Y" ( set "VAL_SG_X_Column2_TwoDigitHex=true" )
															if /i "!VAL_SG_Number_X_Column2!"=="%%Z" ( set "VAL_SG_X_Column2_TwoDigitHex=true" )
														)

														if "!VAL_SG_X_Column2_TwoDigitHex!"=="true" ( 

															set "VAL_SG_Number_X_Column2=!VAL_SG_ObjectX_Column2!"

															@REM Gets the first four digits of the data, indicating the number
															set VAL_SG_Number_X_Column2=!VAL_SG_Number_X_Column2:~0,4!

															@REM Converts hexadecimal numbers to decimal
															set /A VAL_SG_Number_X_Column2=!VAL_SG_Number_X_Column2!

															@REM Include the fifth to ending character as the description of the value
															set "VAL_DescriptionY=!VAL_SG_ObjectX_Column2:~5!"

															for /L %%Z in (1,1,2) do ( set "VAL_DescriptionY=!VAL_DescriptionY:  =!" )

															set "VAL_DescriptionY=!VAL_DescriptionY: =!"
														)^
														else (
															set "VAL_SG_Number_X_Column2=!VAL_SG_ObjectX_Column2!"
															set VAL_SG_Number_X_Column2=!VAL_SG_Number_X_Column2:~0,3!
															set /A VAL_SG_Number_X_Column2=!VAL_SG_Number_X_Column2!
															set "VAL_DescriptionY=!VAL_SG_ObjectX_Column2:~4!"
															for /L %%Z in (1,1,2) do ( set "VAL_DescriptionY=!VAL_DescriptionY:  =!" )
															set "VAL_DescriptionY=!VAL_DescriptionY: =!"
														)

														@REM The data is stored in a format such as VAL_NUMBAER VAL_DESCRIPTION, e.g. 4 Valid 3 Valid ...
														set "VAL_SG_List_Y=!VAL_SG_Number_X_Column2! "!VAL_DescriptionY!""
													)
												)

												@REM 
												set "VAL_SG_X_Column1_TwoDigitHex=false"
												set "VAL_SG_W_TwoDigitHex=false"

												for /L %%Z in (0,1,9) do (
													if /i "!VAL_SG_Number_X_Column1!"=="%%Z" ( set "VAL_SG_X_Column1_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_W!"=="%%Z" ( set "VAL_SG_W_TwoDigitHex=true" )
												)

												for /f "tokens=1-6 delims= " %%U in ("!regStr!") do (

													if /i "!VAL_SG_Number_X_Column1!"=="%%U" ( set "VAL_SG_X_Column1_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_X_Column1!"=="%%V" ( set "VAL_SG_X_Column1_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_X_Column1!"=="%%W" ( set "VAL_SG_X_Column1_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_X_Column1!"=="%%X" ( set "VAL_SG_X_Column1_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_X_Column1!"=="%%Y" ( set "VAL_SG_X_Column1_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_X_Column1!"=="%%Z" ( set "VAL_SG_X_Column1_TwoDigitHex=true" )

													if /i "!VAL_SG_Number_W!"=="%%U" ( set "VAL_SG_W_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_W!"=="%%V" ( set "VAL_SG_W_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_W!"=="%%W" ( set "VAL_SG_W_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_W!"=="%%X" ( set "VAL_SG_W_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_W!"=="%%Y" ( set "VAL_SG_W_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_W!"=="%%Z" ( set "VAL_SG_W_TwoDigitHex=true" )
												)

												@REM Same as above
												set "VAL_SG_Number_X_Column1=!VAL_SG_ObjectX_Column1!"
												if "!VAL_SG_X_Column1_TwoDigitHex!"=="true" ( 
													set VAL_SG_Number_X_Column1=!VAL_SG_Number_X_Column1:~0,4!
													set /A VAL_SG_Number_X_Column1=!VAL_SG_Number_X_Column1!
													set "VAL_DescriptionX=!VAL_SG_ObjectX_Column1:~5!"
													for /L %%Z in (1,1,2) do ( set "VAL_DescriptionX=!VAL_DescriptionX:  =!" )
													set "VAL_DescriptionX=!VAL_DescriptionX: =!"
												)^
												else (
													set VAL_SG_Number_X_Column1=!VAL_SG_Number_X_Column1:~0,3!
													set /A VAL_SG_Number_X_Column1=!VAL_SG_Number_X_Column1!
													set "VAL_DescriptionX=!VAL_SG_ObjectX_Column1:~4!"
													for /L %%Z in (1,1,2) do ( set "VAL_DescriptionX=!VAL_DescriptionX:  =!" )
													set "VAL_DescriptionX=!VAL_DescriptionX: =!"
												)

												@REM Same as above
												if "!VAL_SG_W_TwoDigitHex!"=="true" ( 
													set "VAL_SG_Number_W=!VAL_SG_ObjectW!"
													set VAL_SG_Number_W=!VAL_SG_Number_W:~0,4!
													set /A VAL_SG_Number_W=!VAL_SG_Number_W!
												)^
												else (
													set "VAL_SG_Number_W=!VAL_SG_ObjectW!"
													set VAL_SG_Number_W=!VAL_SG_Number_W:~0,3!
													set /A VAL_SG_Number_W=!VAL_SG_Number_W!
												)

												@REM Combine values and descriptions together
												set "VAL_SG_List_X="
												for /L %%U in (!VAL_SG_Number_X_Column1!,-1,!VAL_SG_Number_W!) do (
													set "VAL_SG_List_X=!VAL_SG_List_X! %%U "!VAL_DescriptionX!""
												)

												@REM 
												set "VAL_SG_List=!VAL_SG_List! !VAL_SG_List_Y! !VAL_SG_List_X!"
											)
										)^
										else ( 
											@REM same as above
											set "VAL_SG_ObjectZ=!VAL_SG_Object!"
											@REM \
											if NOT "!VAL_SG_ObjectZ!"=="!VAL_SG_ObjectZ:0x=_!" ( 

												set VAL_SG_Number_Z=!VAL_SG_ObjectZ:~3,1!

												@REM 
												set "VAL_SG_Z_TwoDigitHex=false"
												for /L %%Z in (0,1,9) do (
													if /i "!VAL_SG_Number_Z!"=="%%Z" ( set "VAL_SG_Z_TwoDigitHex=true" )
												)

												for /f "tokens=1-6 delims= " %%U in ("!regStr!") do (

													if /i "!VAL_SG_Number_Z!"=="%%U" ( set "VAL_SG_Z_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_Z!"=="%%V" ( set "VAL_SG_Z_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_Z!"=="%%W" ( set "VAL_SG_Z_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_Z!"=="%%X" ( set "VAL_SG_Z_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_Z!"=="%%Y" ( set "VAL_SG_Z_TwoDigitHex=true" )
													if /i "!VAL_SG_Number_Z!"=="%%Z" ( set "VAL_SG_Z_TwoDigitHex=true" )
												)

												if "!VAL_SG_Z_TwoDigitHex!"=="true" ( 
													set "VAL_SG_Number_Z=!VAL_SG_ObjectZ!"
													set VAL_SG_Number_Z=!VAL_SG_Number_Z:~0,4!
													set /A VAL_SG_Number_Z=!VAL_SG_Number_Z!
													set "VAL_DescriptionZ=!VAL_SG_ObjectZ:~5!"
													for /L %%Z in (1,1,2) do ( set "VAL_DescriptionZ=!VAL_DescriptionZ:  =!" )
													set "VAL_DescriptionZ=!VAL_DescriptionZ: =!"
												)^
												else (
													set "VAL_SG_Number_Z=!VAL_SG_ObjectZ!"
													set VAL_SG_Number_Z=!VAL_SG_Number_Z:~0,3!
													set /A VAL_SG_Number_Z=!VAL_SG_Number_Z!
													set "VAL_DescriptionZ=!VAL_SG_ObjectZ:~4!"
													for /L %%Z in (1,1,2) do ( set "VAL_DescriptionZ=!VAL_DescriptionZ:  =!" )
													set "VAL_DescriptionZ=!VAL_DescriptionZ: =!"
												)

												@REM Here, the full value and description of a signal have been obtained, and the data is merged in the value-description format
												@REM VAL_ format:VAL_ MessageId SignalName N "DefineN" ... 0 "Define0";
												set "VAL_SG_List_Z=!VAL_SG_Number_Z! "!VAL_DescriptionZ!""
												set "VAL_SG_List=!VAL_SG_List! !VAL_SG_List_Z!"
											)
										)
									)
								)
								
								@REM Determine whether the value description of the signal is null, if it is empty, it is not processed
								if NOT "!VAL_SG_List!"=="" ( 

									set "VAL_SG=VAL_ !BO_MessageId! !SG_SignalName! !VAL_SG_List! ;"
									for /L %%Z in (1,1,2) do ( set "VAL_SG=!VAL_SG:  = !" )
									echo !VAL_SG! >> %VAL_SG_TempFile%

									set "VAL_TABLE=VAL_TABLE_ VtSig_!SG_SignalName! !VAL_SG_List! ;"
									for /L %%Z in (1,1,2) do ( set "VAL_TABLE=!VAL_TABLE:  = !" )
									echo !VAL_TABLE! >> %VAL_TABLE_TempFile%
								)
							)
						)

						@REM SIG_GROUP signal list
						
						set "SIG_GROUP_SignalList=!SIG_GROUP_SignalList! !SG_SignalName!"

						set "SIG_GROUP_Object=!SIG_GROUP_Header! !SIG_GROUP_SignalList!;"

						for /L %%Z in (1,1,2) do set "SIG_GROUP_Object=!SIG_GROUP_Object:  = !"
					)^
					else if "!foundMsgFlg!"=="true" ( 
						@REM obtain network nodes

						@REM Save network nodes for use in determining the sending and receiving nodes of subsequent messages
						for /L %%Z in (1,1,!NetworkNodesNum!) do (
							if "!NetworkNode_%%Z!"=="NULL" (
								set "BU_NetworkNode_%%Z="
							)^
							else (
								set "BU_NetworkNode_%%Z=!NetworkNode_%%Z!"
							)
						)

						@REM Merge network nodes into one line, separated by spaces
						set "BU_NetworkNodes="
						for /L %%Z in (1,1,!NetworkNodesNum!) do (
							set "BU_NetworkNodes=!BU_NetworkNodes! !BU_NetworkNode_%%Z!"
						)

						@REM Network Nodess format: BU_ NetworkNode1 NetworkNode2 ..
						set "BU_NetworkNodes=BU_: !BU_NetworkNodes!"

						@REM Merge two adjacent spaces into one space
						for /L %%Z in (1,1,2) do set "BU_NetworkNodes=!BU_NetworkNodes:  = !"

						@REM Save the 'BU_' section to the output file
						echo !BU_NetworkNodes! >> %outputFile%

					)^
					else (
						@REM obtain messages
						@REM log the number of messages
						set /A messagesNum+=1

						@REM The default sending node of a message is "Vector__XXX"
						set "TransmitterNode=Vector__XXX"

						@REM Obtain the sending node of the message
						for /L %%Z in (1,1,!NetworkNodesNum!) do ( 

							@REM Determine the sending node of the message, and if not, keep the sending node as "Vector__XXX"
							if "!TransmitterNode!"=="Vector__XXX" (
								if /i "!NetworkNode_%%Z!"=="S" ( set "TransmitterNode=!BU_NetworkNode_%%Z!" )
							)
						)
						
						@REM Message format: BO_ MessageId MessageName: MessageSize Transmitter
						set /A BO_MessageId=%%c
						set /A BO_MsgByteLength=%%f
						set "BO_Message=BO_ !BO_MessageId! !MsgName!: !BO_MsgByteLength! !TransmitterNode!"
						
						@REM Output the message to a temporary file
						echo, >> %BO_SG_TempFile%
						echo !BO_Message! >> %BO_SG_TempFile%

						@REM Obtain the current message ID and use it in the signal comment
						set "CM_SG_MsgId=CM_ SG_ !BO_MessageId!"

						@REM BA_ Name ObjectType ObjectName AttributeValue;

						@REM message type
						set "BA_MsgType=%%b"

						@REM messge send type
						set "BA_MsgSendType=%%d"

						@REM message cycle
						set "BA_MsgCycle=%%e"

						for /L %%Z in (1,1,2) do (set "BA_MsgCycle=!BA_MsgCycle: =NULL!")

						@REM message cycle fast
						set "BA_MsgCycleFast=%%A"

						@REM The number of times the message was sent repeatedly
						set "BA_MsgNrOfRep=%%B"

						@REM The delay in sending the message
						set "BA_MsgDelayTime=%%C" 

						@REM When the current message is a network management message, it is processed
						if /i !BA_MsgType!==!MsgType_NM! ( 
							
							@REM 
							set "NmMsgId=%%c"
							@REM the number of network management message
							set /A nmMessageCount+=1

							@REM NM_ID = nmBaseAddress + nmStationAddress
							set /A nmStationAddress=0x!NmMsgId:~3,2!
							set /A nmBaseAddress=!NmMsgId:~0,3!00

							@REM NmNode format:BA_ "NmNode" BU_ !TransmitterNode! 1;"
							set "BA_BU_NmNode=BA_ "NmNode" BU_ !TransmitterNode! 1;"
							set "BA_BU_NmStationAddress=BA_ "NmStationAddress" BU_ !TransmitterNode! !nmStationAddress!;"
							
							echo !BA_BU_NmStationAddress! >> %BA_BU_TempFile%
							echo !BA_BU_NmNode! >> %BA_BU_TempFile%

							@REM set "BA_BO_NmMessage=BA_ "NmMessage" BO_ !BO_MessageId! 1;"
							@REM TBD:2023/4/13,The exact purpose of this property is not known
							@REM echo !BA_BO_NmMessage! >> %BA_BO_TempFile%
						)^
						else if /i !BA_MsgType!==!MsgType_Diag! ( 

							@REM diagnostic station address
							set /A diagStationAddress=0x!BO_MessageId:~3,2!
						
							for /L %%Z in (1,1,!NetworkNodesNum!) do (
								if !TransmitterNode!==!NetworkNode_%%Z! ( set /A DiagNode_%%Z+=1 )
							)

							@REM Use the diagnostic message to calculate the diagnostic node to which it currently belongs and calculate its station address
							for /L %%Z in (1,1,!NetworkNodesNum!) do (
								if !NetworkNode_%%Z!==!TransmitterNode! (
									if !DiagNode_%%Z! EQU 1 ( 
										set "BA_BU_DiagStationAddress=BA_ "DiagStationAddress" BU_ !TransmitterNode! !diagStationAddress!;"
										echo !BA_BU_DiagStationAddress! >> %BA_BU_TempFile%
									)
								)
							)

							@REM DiagState attribute format:BA_ "DiagState" BO_ MessageId 1;
							set "BA_BO_DiagState=BA_ "DiagState" BO_ !BO_MessageId! 1;"
							echo !BA_BO_DiagState! >> %BA_BO_TempFile%

							@REM Only by obtaining the node that sends the "function-addressing" message can you determine whether other diagnostic messages are 
							@REM diagnostic response messages or diagnostic request messages. Therefore, keep "Functional Addressing Messages" in front of other diagnostic messages
							if /i !BO_MessageId!==0x7DF ( 
								set "diagReqTesterNode=!TransmitterNode!"
								set "BA_BO_DiagRequest=BA_ "DiagRequest" BO_ !BO_MessageId! 1;"
								echo !BA_BO_DiagRequest! >> %BA_BO_TempFile%
								set "DiagReqNodeFound=true"
							)^
							else  ( 
								if "!DiagReqNodeFound!"=="true" (
									if !TransmitterNode!==!diagReqTesterNode! (
										set "BA_BO_DiagResponse=BA_ "DiagRequest" BO_ !BO_MessageId! 1;"
										echo !BA_BO_DiagResponse! >> %BA_BO_TempFile%
									)^
									else (
										set "BA_BO_DiagRequest=BA_ "DiagResponse" BO_ !BO_MessageId! 1;"
										echo !BA_BO_DiagRequest! >> %BA_BO_TempFile%
									)
								)
							)
						)

						@REM If the message period is empty, such as an event message, it is not processed, otherwise it needs to be processed
						if NOT "!BA_MsgCycle!"=="NULL" (
							set "BA_BO_GenMsgCycleTime=BA_ "GenMsgCycleTime" BO_ !BO_MessageId! !BA_MsgCycle!;"
							echo !BA_BO_GenMsgCycleTime! >> %BA_BO_TempFile%
						)

						@REM If a message does not need to be sent quickly and repeatedly, it is not processed, otherwise it needs to be processed
						if NOT "!BA_MsgNrOfRep!"=="NULL" (

							@REM 
							set "BA_BO_GenMsgNrOfRepetition=BA_ "GenMsgNrOfRepetition" BO_ !BO_MessageId! !BA_MsgNrOfRep!;"
							set "BA_BO_GenMsgCycleTimeFast=BA_ "GenMsgCycleTimeFast" BO_ !BO_MessageId! !BA_MsgCycleFast!;"
							
							echo !BA_BO_GenMsgNrOfRepetition! >> %BA_BO_TempFile%
							echo !BA_BO_GenMsgCycleTimeFast! >> %BA_BO_TempFile%

							if NOT "!BA_MsgDelayTime!"=="NULL" (

								@REM 
								set "BA_BO_GenMsgDelayTime=BA_ "GenMsgDelayTime" BO_ !BO_MessageId! !BA_MsgDelayTime!;"
								echo !BA_BO_GenMsgDelayTime! >> %BA_BO_TempFile%
							)
						)

						@REM "Cyclic","IfActive","Event","CA","CE","NoMsgSendType";
						if "!BA_MsgSendType!"=="IfActive" (
							set "BA_BO_GenMsgCycleTime=BA_ "GenMsgSendType" BO_ !BO_MessageId! 1;"
							echo !BA_BO_GenMsgCycleTime! >> %BA_BO_TempFile%
						)^
						else if "!BA_MsgSendType!"=="Event" (
							set "BA_BO_GenMsgCycleTime=BA_ "GenMsgSendType" BO_ !BO_MessageId! 2;"
							echo !BA_BO_GenMsgCycleTime! >> %BA_BO_TempFile%
						)^
						else if "!BA_MsgSendType!"=="CA" (
							set "BA_BO_GenMsgCycleTime=BA_ "GenMsgSendType" BO_ !BO_MessageId! 3;"
							echo !BA_BO_GenMsgCycleTime! >> %BA_BO_TempFile%
						)^
						else if "!BA_MsgSendType!"=="CE" (
							set "BA_BO_GenMsgCycleTime=BA_ "GenMsgSendType" BO_ !BO_MessageId! 4;"
							echo !BA_BO_GenMsgCycleTime! >> %BA_BO_TempFile%
						)^
						else if "!BA_MsgSendType!"=="NoMsgSendType" (
							set "BA_BO_GenMsgCycleTime=BA_ "GenMsgSendType" BO_ !BO_MessageId! 5;"
							echo !BA_BO_GenMsgCycleTime! >> %BA_BO_TempFile%
						)^
						else (
							echo, > nul
						)
						
						@REM save signal group to temporary file
						if NOT "!SIG_GROUP_SignalList!"=="" (

							@REM 
							echo !SIG_GROUP_Object! >> %SIG_GROUP_TempFile%
							set "SIG_GROUP_SignalList="
						)

						set "SIG_GROUP_Header=SIG_GROUP_ !BO_MessageId! SG_!MsgName! 1 : "
					)
				)
			)
        )

		@REM Save the current value of 2 modulo for the number of '"' symbols for the next calculation
        set /A modValLast=!modVal!
    )

	@REM @REM Converted 45%
	echo 				  ^|         Converted to 45%%, Please wait^^!       ^|

	@REM To be enable
	@REM if exist %VAL_TABLE_TempFile% ( 
	@REM 	type %VAL_TABLE_TempFile% >> %outputFile%
	@REM )

	@REM @REM Converted 55%
	echo 				  ^|         Converted to 55%%, Please wait^^!       ^|

	echo, >> %outputFile%
	echo, >> %outputFile%

	@REM 
	if exist %BO_SG_TempFile% ( 
		type %BO_SG_TempFile% >> %outputFile%
	)

	@REM @REM Converted 65%
	echo 				  ^|         Converted to 65%%, Please wait^^!       ^|

	echo, >> %outputFile%
	echo, >> %outputFile%
	echo, >> %outputFile%

	@REM network comment
	set "BU_NetworkNodes=!BU_NetworkNodes:BU_: =!"
	set "BU_NetworkNodes=!BU_NetworkNodes: =   !"
	set "releaseDate=%DATE%"
	set "releaseDate=!releaseDate:~3!"
	
	echo CM_ ^"Network name:  !onlyNameInputFile! >> %outputFile%
	echo, >> %outputFile%
	echo Release date:  !releaseDate! >> %outputFile%
	echo, >> %outputFile%
	echo Creator:  %username% >> %outputFile%
	echo, >> %outputFile%
	echo Description:  Describe the purpose of the network. >> %outputFile%
	echo, >> %outputFile%
	echo Nodes List:  !BU_NetworkNodes! >> %outputFile%
	echo, >> %outputFile%
	echo Number of messages:  !messagesNum! >> %outputFile%
	echo, >> %outputFile%
	echo Number of signals:  !signalsNum! >> %outputFile%
	echo, >> %outputFile%
	echo Bus:  The bus defaults to CAN. >> %outputFile%
	echo, >> %outputFile%
	echo Project:  !onlyNameInputFile! >> %outputFile%
	echo, >> %outputFile%
	echo Customer:  Such as: BYD >> %outputFile%
	echo, >> %outputFile%
	echo Revision history:  Describe the content of the change. ^"; >> %outputFile%

	@REM node comment
	for /L %%Z in (1,1,!NetworkNodesNum!) do (
		echo CM_ BU_ !BU_NetworkNode_%%Z! "!BU_NetworkNode_%%Z!"; >> %outputFile% 
	)
    
	@REM 
	if exist %CM_SG_TempFile% ( 
		type %CM_SG_TempFile% >> %outputFile%
	)

	echo BA_DEF_  "BusType" STRING ; >> %outputFile%
	echo BA_DEF_  "DBName" STRING ; >> %outputFile%
	echo BA_DEF_  "NmType" STRING ; >> %outputFile%
	echo BA_DEF_  "Baudrate" INT 0 1000000; >>  %outputFile%
	echo BA_DEF_  "Manufacturer" STRING ; >> %outputFile%
	echo BA_DEF_  "IlTxTimeout" INT 0 65535; >>  %outputFile%
	echo BA_DEF_  "MultiplexExtEnabled" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_  "NmMessageCount" INT 1 255; >>  %outputFile%
	echo BA_DEF_  "NmBaseAddress" HEX 0 2047; >>  %outputFile%
	echo BA_DEF_  "NmAsrBaseAddress" HEX 0 65535; >>  %outputFile%
	echo BA_DEF_  "NmAsrCanMsgCycleTime" INT 0 65535; >>  %outputFile%
	echo BA_DEF_  "NmAsrMessageCount" INT 0 255; >>  %outputFile%
	echo BA_DEF_  "NmAsrRepeatMessageTime" INT 0 65535; >>  %outputFile%
	echo BA_DEF_  "NmAsrTimeoutTime" INT 0 65535; >>  %outputFile%
	echo BA_DEF_  "NmAsrWaitBusSleepTime" INT 0 65535; >>  %outputFile%
	echo BA_DEF_  "GenEnvVarEndingDsp" STRING ; >> %outputFile%
	echo BA_DEF_  "GenEnvVarEndingSnd" STRING ; >> %outputFile%
	echo BA_DEF_  "GenEnvVarPrefix" STRING ; >> %outputFile%
	echo BA_DEF_ BU_  "ECU" STRING ; >> %outputFile%
	echo BA_DEF_ BU_  "NmNode" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BU_  "ILUsed" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BU_  "CANoeStartDelay" INT 0 0; >>  %outputFile%
	echo BA_DEF_ BU_  "CANoeDrift" INT 0 0; >>  %outputFile%
	echo BA_DEF_ BU_  "CANoeJitterMin" INT 0 0; >>  %outputFile%
	echo BA_DEF_ BU_  "CANoeJitterMax" INT 0 0; >>  %outputFile%
	echo BA_DEF_ BU_  "NmStationAddress" HEX 0 0; >>  %outputFile%
	echo BA_DEF_ BU_  "DiagStationAddress" HEX 0 255; >>  %outputFile%
	echo BA_DEF_ BU_  "NmAsrNode" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BU_  "NmAsrCanMsgCycleOffset" INT 0 65535; >>  %outputFile%
	echo BA_DEF_ BU_  "NmAsrCanMsgReducedTime" INT 0 65535; >>  %outputFile%
	echo BA_DEF_ BU_  "NmAsrNodeIdentifier" HEX 0 597; >>  %outputFile%
	echo BA_DEF_ BU_  "GenNodSleepTime" INT 0 1000000; >>  %outputFile%
	echo BA_DEF_ BU_  "NodeLayerModules" STRING ; >> %outputFile%
	echo BA_DEF_ BU_  "GenNodAutoGenSnd" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BO_  "NmMessage" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BO_  "DiagRequest" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BO_  "DiagResponse" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BO_  "DiagState" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BO_  "GenMsgILSupport" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BO_  "NmAsrMessage" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BO_  "GenMsgCycleTimeFast" INT 0 0; >>  %outputFile%
	echo BA_DEF_ BO_  "GenMsgStartDelayTime" INT 0 0; >>  %outputFile%
	echo BA_DEF_ BO_  "DiagUUDTResponse" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BO_  "DiagConnection" INT 0 65535; >>  %outputFile%
	echo BA_DEF_ BO_  "GenMsgSendType" ENUM  "Cyclic","IfActive","Event","CA","CE","NoMsgSendType"; >>  %outputFile%
	echo BA_DEF_ BO_  "GenMsgCycleTimeActive" INT 0 0; >>  %outputFile%
	echo BA_DEF_ BO_  "GenMsgCycleTime" INT 0 50000; >>  %outputFile%
	echo BA_DEF_ BO_  "GenMsgDelayTime" INT 0 1000; >>  %outputFile%
	echo BA_DEF_ BO_  "GenMsgNrOfRepetition" INT 0 1000; >>  %outputFile%
	echo BA_DEF_ BO_  "GenMsgAltSetting" STRING ; >> %outputFile%
	echo BA_DEF_ BO_  "GenMsgAutoGenDsp" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BO_  "GenMsgAutoGenSnd" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ BO_  "GenMsgConditionalSend" STRING ; >> %outputFile%
	echo BA_DEF_ BO_  "GenMsgEVName" STRING ; >> %outputFile%
	echo BA_DEF_ BO_  "GenMsgPostIfSetting" STRING ; >> %outputFile%
	echo BA_DEF_ BO_  "GenMsgPostSetting" STRING ; >> %outputFile%
	echo BA_DEF_ BO_  "GenMsgPreIfSetting" STRING ; >> %outputFile%
	echo BA_DEF_ BO_  "GenMsgPreSetting" STRING ; >> %outputFile%
	echo BA_DEF_ BO_  "CANFD_BRS" ENUM  "0","1"; >>  %outputFile%
	echo BA_DEF_ BO_  "VFrameFormat" ENUM  "StandardCAN","ExtendedCAN","StandardCAN_FD","ExtendedCAN_FD"; >>  %outputFile%
	echo BA_DEF_ SG_  "GenSigSendType" ENUM  "Cyclic","OnWrite","OnWriteWithRepetition","OnChange","OnChangeWithRepetition","IfActive","IfActiveWithRepetition","NoSigSendType"; >>  %outputFile%
	echo BA_DEF_ SG_  "GenSigCycleTime" INT 0 0; >>  %outputFile%
	echo BA_DEF_ SG_  "GenSigCycleTimeActive" INT 0 0; >>  %outputFile%
	echo BA_DEF_ SG_  "GenSigInactiveValue" INT 0 100000; >>  %outputFile%
	echo BA_DEF_ SG_  "GenSigStartValue" FLOAT 0 100000000000; >>  %outputFile%
	echo BA_DEF_ SG_  "GenSigAltSetting" STRING ; >> %outputFile%
	echo BA_DEF_ SG_  "GenSigAssignSetting" STRING ; >> %outputFile%
	echo BA_DEF_ SG_  "GenSigAutoGenDsp" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ SG_  "GenSigAutoGenSnd" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_ SG_  "GenSigConditionalSend" STRING ; >> %outputFile%
	echo BA_DEF_ SG_  "GenSigEnvVarType" ENUM  "int","float","undef"; >>  %outputFile%
	echo BA_DEF_ SG_  "GenSigEVName" STRING ; >> %outputFile%
	echo BA_DEF_ SG_  "GenSigPostIfSetting" STRING ; >> %outputFile%
	echo BA_DEF_ SG_  "GenSigPostSetting" STRING ; >> %outputFile%
	echo BA_DEF_ SG_  "GenSigPreIfSetting" STRING ; >> %outputFile%
	echo BA_DEF_ SG_  "GenSigPreSetting" STRING ; >> %outputFile%
	echo BA_DEF_ SG_  "GenSigReceiveSetting" STRING ; >> %outputFile%
	echo BA_DEF_ EV_  "GenEnvControlType" ENUM  "NoControl","SliderHoriz","SliderVert","PushButton","Edit","BitmapSwitch"; >>  %outputFile%
	echo BA_DEF_ EV_  "GenEnvMsgName" STRING ; >> %outputFile%
	echo BA_DEF_ EV_  "GenEnvMsgOffset" INT 0 999999999; >>  %outputFile%
	echo BA_DEF_ EV_  "GenEnvAutoGenCtrl" ENUM  "No","Yes"; >>  %outputFile%
	echo BA_DEF_REL_ BU_SG_REL_  "NodeMapRxSig" INT 0 0; >>  %outputFile%
	echo BA_DEF_REL_ BU_BO_REL_  "NodeTxMsg" INT 0 0; >>  %outputFile%
	echo BA_DEF_REL_ BU_SG_REL_  "GenSigTimeoutTime" INT 0 65535; >>  %outputFile%
	echo BA_DEF_DEF_  "BusType" "CAN"; >>  %outputFile%
	echo BA_DEF_DEF_  "DBName" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "NmType" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "Baudrate" 500000; >>  %outputFile%
	echo BA_DEF_DEF_  "Manufacturer" "CompanyName"; >>  %outputFile%
	echo BA_DEF_DEF_  "IlTxTimeout" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "MultiplexExtEnabled" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "NmMessageCount" 128; >>  %outputFile%
	echo BA_DEF_DEF_  "NmBaseAddress" 1280; >>  %outputFile%
	echo BA_DEF_DEF_  "NmAsrBaseAddress" 1280; >>  %outputFile%
	echo BA_DEF_DEF_  "NmAsrCanMsgCycleTime" 100; >>  %outputFile%
	echo BA_DEF_DEF_  "NmAsrMessageCount" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "NmAsrRepeatMessageTime" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "NmAsrTimeoutTime" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "NmAsrWaitBusSleepTime" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenEnvVarEndingDsp" "Dsp_"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenEnvVarEndingSnd" "_"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenEnvVarPrefix" "Env"; >>  %outputFile%
	echo BA_DEF_DEF_  "ECU" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "NmNode" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "ILUsed" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "CANoeStartDelay" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "CANoeDrift" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "CANoeJitterMin" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "CANoeJitterMax" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "NmStationAddress" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "DiagStationAddress" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "NmAsrNode" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "NmAsrCanMsgCycleOffset" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "NmAsrCanMsgReducedTime" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "NmAsrNodeIdentifier" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenNodSleepTime" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "NodeLayerModules" "CANoeILNLVector.dll"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenNodAutoGenSnd" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "NmMessage" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "DiagRequest" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "DiagResponse" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "DiagState" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgILSupport" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "NmAsrMessage" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgCycleTimeFast" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgStartDelayTime" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "DiagUUDTResponse" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "DiagConnection" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgSendType" "Cyclic"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgCycleTimeActive" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgCycleTime" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgDelayTime" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgNrOfRepetition" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgAltSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgAutoGenDsp" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgAutoGenSnd" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgConditionalSend" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgEVName" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgPostIfSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgPostSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgPreIfSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenMsgPreSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "CANFD_BRS" "0"; >>  %outputFile%
	echo BA_DEF_DEF_  "VFrameFormat" "StandardCAN"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigSendType" "Cyclic"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigCycleTime" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigCycleTimeActive" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigInactiveValue" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigStartValue" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigAltSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigAssignSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigAutoGenDsp" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigAutoGenSnd" "No"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigConditionalSend" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigEnvVarType" "undef"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigEVName" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigPostIfSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigPostSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigPreIfSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigPreSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenSigReceiveSetting" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenEnvControlType" "NoControl"; >>  %outputFile%
	echo BA_DEF_DEF_  "GenEnvMsgName" ""; >>  %outputFile%
	echo BA_DEF_DEF_  "GenEnvMsgOffset" 0; >>  %outputFile%
	echo BA_DEF_DEF_  "GenEnvAutoGenCtrl" "No"; >>  %outputFile%
	echo BA_DEF_DEF_REL_ "NodeMapRxSig" 0; >>  %outputFile%
	echo BA_DEF_DEF_REL_ "NodeTxMsg" 0; >>  %outputFile%
	echo BA_DEF_DEF_REL_ "GenSigTimeoutTime" 0; >>  %outputFile%
	echo BA_ "DBName" "!onlyNameInputFile!"; >>  %outputFile%
	echo BA_ "NmBaseAddress" !nmBaseAddress!; >>  %outputFile%
	echo BA_ "NmMessageCount" !nmMessageCount!; >>  %outputFile%

	@REM @REM Converted 85%
	echo 				  ^|         Converted to 85%%, Please wait^^!       ^|

	@REM 
	if exist %BA_BU_TempFile% (
		type %BA_BU_TempFile% >> %outputFile%
	)

	@REM 
	if exist %BA_BO_TempFile% ( 
		type %BA_BO_TempFile% >> %outputFile%
	)

	@REM @REM Converted 95%
	echo 				  ^|         Converted to 95%%, Please wait^^!       ^|

	@REM 
	if exist %BA_SG_TempFile% ( 
		type %BA_SG_TempFile% >> %outputFile%
	)

	@REM 
	if exist %VAL_SG_TempFile% ( 
		type %VAL_SG_TempFile% >> %outputFile%
	)

	@REM 
	if "!SignalGroupFlg!"=="1" (
		if exist %SIG_GROUP_TempFile% ( 
			type %SIG_GROUP_TempFile% >> %outputFile%
		)
	)

	@REM @REM Converted 100%
	echo 				  ^|        Converted to 100%%, Please wait^^!       ^|

	@REM 
	set "ConversionSuccessFlg=true"

	@REM delete temporary files
	if exist %BO_SG_TempFile% (del %BO_SG_TempFile%)
	@REM if exist %CM_BU_TempFile% (del %CM_BU_TempFile%)
	@REM if exist %CM_BO_TempFile% (del %CM_BO_TempFile%)
	if exist %CM_SG_TempFile% (del %CM_SG_TempFile%)
	if exist %BA_BU_TempFile% (del %BA_BU_TempFile%)
	if exist %BA_BO_TempFile% (del %BA_BO_TempFile%)
	if exist %BA_SG_TempFile% (del %BA_SG_TempFile%)
	if exist %VAL_SG_TempFile% (del %VAL_SG_TempFile%)
	if exist %VAL_TABLE_TempFile% (del %VAL_TABLE_TempFile%)
	if exist %SIG_GROUP_TempFile% (del %SIG_GROUP_TempFile%)
	if exist %tempCSVFile% (del %tempCSVFile%)
	@REM if exist %tempVbsFile% ( del %tempVbsFile% )

	@REM End convert *.csv file to *.dbc file
	if /i "!OneIsAllFlg!"=="1" (

		call:OneIsAll %outputFile%
	)^
	else (
		goto EndConversion
	)

@REM ================================================================================================
@REM ====================================   End: CSV Conversion  ====================================
@REM ================================================================================================


@REM ================================================================================================
@REM ===================================   Start: VBS Script  =======================================
@REM ================================================================================================

@REM 将 xls\xlsx 文件转换为 Csv 文件
:XlsToCsv

	@REM 
	set "tempVbsFile=C:\Windows\Temp\Temp_VBS_Script.vbs"
	Set "tempCSVFile=C:\Windows\Temp\Temp_CSVFile.csv"

	echo ExportExcelFileToCSV(Wscript.Arguments(0)) > %tempVbsFile%
	echo,  >> %tempVbsFile%
	echo WScript.Quit(0) >> %tempVbsFile%
	echo,  >> %tempVbsFile%
	echo Function ExportExcelFileToCSV(sFilename) >> %tempVbsFile%
	echo,  >> %tempVbsFile%
	echo     '* Settings >> %tempVbsFile%
	echo     Dim oExcel, oFSO, oExcelFile >> %tempVbsFile%
	echo     Set oExcel = CreateObject("Excel.Application") >> %tempVbsFile%
	echo     Set oFSO = CreateObject("Scripting.FileSystemObject") >> %tempVbsFile%
	echo     iCSV_Format = 6 >> %tempVbsFile%
	echo,  >> %tempVbsFile%
	echo     '* Set Up >> %tempVbsFile%
	echo     sExtension = oFSO.GetExtensionName(sFilename) >> %tempVbsFile%
	echo,  >> %tempVbsFile%
	echo     sAbsoluteSource = oFSO.GetAbsolutePathName(sFilename) >> %tempVbsFile%
	echo     sThisDestination = Wscript.Arguments(1) >> %tempVbsFile%
	echo,  >> %tempVbsFile%
	echo     '* Do Work >> %tempVbsFile%
	echo     Set oExcelFile = oExcel.Workbooks.Open(sAbsoluteSource) >> %tempVbsFile%
	echo,  >> %tempVbsFile%
	echo     oExcel.DisplayAlerts = False >> %tempVbsFile%
	echo     If oExcelFile.Sheets.Count = 1 Then >> %tempVbsFile%
	echo         oExcelFile.SaveAs sThisDestination, iCSV_Format >> %tempVbsFile%
	echo     Else >> %tempVbsFile%
	echo         For Each oSheet in oExcelFile.Sheets >> %tempVbsFile%
	echo             If oSheet.Name = "!MatrixSheetName!" Then >> %tempVbsFile%
	echo                 oExcelFile.Sheets(oSheet.Name).Select >> %tempVbsFile%
	echo                 oExcelFile.SaveAs sThisDestination, iCSV_Format >> %tempVbsFile%
	echo             End If >> %tempVbsFile%
	echo         Next >> %tempVbsFile%
	echo     End If >> %tempVbsFile%
	echo     oExcel.DisplayAlerts = True >> %tempVbsFile%
	echo,  >> %tempVbsFile%
	echo     '* Take Down >> %tempVbsFile%
	echo     oExcelFile.Close False >> %tempVbsFile%
	echo     oExcel.Quit >> %tempVbsFile%
	echo,  >> %tempVbsFile%
	echo End Function >> %tempVbsFile%

	@REM 
	if exist %tempVbsFile% (

		@REM 
		start %tempVbsFile% %fullPathInputFile% %tempCSVFile%

		if exist %tempCSVFile% (
			set "fullPathInputFile=%tempCSVFile%"
		)

	)

	@REM 
	goto CsvFileConversion


@REM 将 Csv 文件转换为 xlsx 文件
:CsvToXls

	@REM 
	set "tempVbsFile=C:\Windows\Temp\Temp_VBS_Script.vbs"
	set "CsvToXlsFile=%cd%\!CsvToXlsFile!"
	set "tmpCsvToXlsFile=%cd%\!onlyNameInputFile!.xlsx"
	if exist !tmpCsvToXlsFile! (del !tmpCsvToXlsFile!)

	echo Set oExcel= CreateObject("Excel.Application")  > !tempVbsFile!
	echo oExcel.Visible = False >> !tempVbsFile!
	echo Set xlsx = oExcel.WorkBooks.Add >> !tempVbsFile!
	echo oExcel.ActiveWorkbook.SaveAs( "!tmpCsvToXlsFile!" ) >> !tempVbsFile!
	
	echo Set xlsx = oExcel.Workbooks.Open("!tmpCsvToXlsFile!")  >> !tempVbsFile!
	echo Set csv = oExcel.Workbooks.Open("!CsvToXlsFile!")  >> !tempVbsFile!

	echo oExcel.DisplayAlerts = False >> !tempVbsFile!
	echo csv.Sheets(1).Copy xlsx.Sheets(1) >> !tempVbsFile!
	
	echo sheetName = "Sheet1" >> !tempVbsFile!

	echo For Each objWorksheet in xlsx.Worksheets >> !tempVbsFile!
	echo 	If objWorksheet.Name = sheetName Then >> !tempVbsFile!
	echo 		objWorksheet.Delete >> !tempVbsFile!
	echo 		Exit For >> !tempVbsFile!
	echo 	End If >> !tempVbsFile!
	echo Next >> !tempVbsFile!

	echo oExcel.Workbooks(1).Save >> !tempVbsFile!
	echo oExcel.DisplayAlerts = True >> !tempVbsFile!

	echo oExcel.WorkBooks.Close  >> !tempVbsFile!
	echo oExcel.Quit >> !tempVbsFile!
	echo WScript.Quit(0) >> !tempVbsFile!

	start !tempVbsFile!

	@REM 
	goto:eof

@REM ================================================================================================
@REM ====================================   End: VBS Script  ========================================
@REM ================================================================================================


@REM ================================================================================================
@REM ====================================   Start: Graphviz  ========================================
@REM ================================================================================================

@REM 附加功能，生成节点交互图、简易的底层通信报文结构体
:OneIsAll

	set "DBCFileName=%1"
	if exist !DBCFileName! (

		@REM 
		set "nodeGraphicsFile=!onlyNameInputFile!.gv"
		if exist !nodeGraphicsFile! ( del !nodeGraphicsFile! )

		@REM 生成节点交互图
		echo digraph nodeDiagram ^{ >> !nodeGraphicsFile!	
		echo, >> !nodeGraphicsFile!

		echo     graph [ >> !nodeGraphicsFile!
		echo        label = "!onlyNameInputFile! Node Interaction Diagram" >> !nodeGraphicsFile!	
		echo        labelloc = t >> !nodeGraphicsFile!	
		echo        rankdir = LR >> !nodeGraphicsFile!	
		echo        ranksep = 10 >> !nodeGraphicsFile!
		echo        fontsize = 40 >> !nodeGraphicsFile!
		echo     ] >> !nodeGraphicsFile!	
		echo, >> !nodeGraphicsFile!	

		echo     node [ >> !nodeGraphicsFile!	
		echo        shape = circle >> !nodeGraphicsFile!	
		echo        color = gray >> !nodeGraphicsFile!	
		echo        style = filled >> !nodeGraphicsFile!	
		echo     ] >> !nodeGraphicsFile!	
		echo, >> !nodeGraphicsFile!	

		echo     edge [ >> !nodeGraphicsFile!	
		echo        color = black >> !nodeGraphicsFile!	
		echo     ] >> !nodeGraphicsFile!
		echo, >> !nodeGraphicsFile!

		@REM 生成简易的底层通信报文结构体
		set "tmpHearderFile=tmp.h"
		if exist !tmpHearderFile! ( del !tmpHearderFile! )

		@REM 
		set "generateBSWCodeSourceFile=!onlyNameInputFile!.c"
		if exist !generateBSWCodeSourceFile! ( del !generateBSWCodeSourceFile! )

		@REM 
		set "generateBSWCodeHeaderFile=!onlyNameInputFile!.h"
		if exist !generateBSWCodeHeaderFile! ( del !generateBSWCodeHeaderFile! )

		echo #include "!generateBSWCodeHeaderFile!" >> !generateBSWCodeSourceFile!
		echo, >> !generateBSWCodeSourceFile!

		echo #ifndef !onlyNameInputFile!_H >> !generateBSWCodeHeaderFile!
		echo #define !onlyNameInputFile!_H >> !generateBSWCodeHeaderFile!
		echo, >> !generateBSWCodeHeaderFile!
		echo, >> !generateBSWCodeHeaderFile!
		
		FOR /F "skip=36 tokens=* usebackq" %%Z in ("!DBCFileName!") do (

			@REM 
			set "tmpDbcRowsData=%%Z"

			if NOT "!tmpDbcRowsData!"=="" (

				@REM 
				if "!tmpDbcRowsData!"=="!tmpDbcRowsData:CM_=_!" (

					@REM 
					if "!tmpDbcRowsData!"=="!tmpDbcRowsData:BO_=_!" (

						@REM 
						FOR /F "tokens=2,3,7 delims=: " %%X in ("!tmpDbcRowsData!") do (
							set "tmpSendSignal=%%X"
							set "tmpSignalSize=%%Y"
							set "tmpReceiveNode=%%Z"
						)

						FOR /F "tokens=2 delims=|@" %%Z in ("!tmpSignalSize!") do (
							echo 	unsigned char  !tmpSendSignal! : %%Z; >> !generateBSWCodeHeaderFile!
						)

						@REM 
						set "BSWSignalEndFlg=true"
						

						if NOT "!tmpReceiveNode!"=="Vector__XXX" (

							@REM 
							if "!displayMsgFlg!"=="true" (

								@REM 
								set "tmpGraphvizRowsData=!tmpGraphvizSendNode! -^> !tmpReceiveNode!"
								echo     !tmpGraphvizRowsData! >> !nodeGraphicsFile!

								@REM 
								set "tmpGraphvizRowsData=[label=""
								echo     !tmpGraphvizRowsData! >> !nodeGraphicsFile!

								@REM 
								if "!OnlyDisplayMsgGraphvizFlg!"=="1" (

									@REM 
									set "tmpGraphvizRowsData=!tmpGraphvizSendMsg!"
								)^
								else (

									@REM 
									set "tmpGraphvizRowsData=!tmpGraphvizSendMsg! :"
								)

								@REM 
								echo     	!tmpGraphvizRowsData! >> !nodeGraphicsFile!


								set "displayMsgFlg=false"
							)

							if NOT "!OnlyDisplayMsgGraphvizFlg!"=="1" (

								@REM 
								set "tmpGraphvizRowsData=!tmpSendSignal!"
								echo     		!tmpGraphvizRowsData! >> !nodeGraphicsFile!
							)

							@REM 
							set "GVSignalEndFlg=true"
						)
					)^
					else (
						
						@REM 
						set "displayMsgFlg=true"

						if "!GVSignalEndFlg!"=="true" (
							set "tmpGraphvizRowsData="];"
							echo     !tmpGraphvizRowsData! >> !nodeGraphicsFile!
							echo, >> !nodeGraphicsFile!
							set "GVSignalEndFlg=false"
						)

						if "!BSWSignalEndFlg!"=="true" (
							echo } _c_!tmpGraphvizSendMsg!_msgType; >> !generateBSWCodeHeaderFile!
							echo, >> !generateBSWCodeHeaderFile!
							set "BSWSignalEndFlg=false"
						)

						@REM 
						FOR /F "tokens=3,5 delims=: " %%Y in ("!tmpDbcRowsData!") do (
							set "tmpGraphvizSendMsg=%%Y"
							set "tmpGraphvizSendNode=%%Z"
						)

						@REM 
						echo typedef struct _c_!tmpGraphvizSendMsg!_msgTypeTag >> !generateBSWCodeHeaderFile!
						echo { >> !generateBSWCodeHeaderFile!

						echo typedef union _c_!tmpGraphvizSendMsg!_bufTag >> !tmpHearderFile!
						echo { >> !tmpHearderFile!
						echo 	unsigned char _c[8]; >> !tmpHearderFile!
						echo 	_c_!tmpGraphvizSendMsg!_msgType !tmpGraphvizSendMsg!; >> !tmpHearderFile!
						echo } _c_!tmpGraphvizSendMsg!_buf; >> !tmpHearderFile!
						echo, >> !tmpHearderFile!

						echo extern _c_!tmpGraphvizSendMsg!_buf !tmpGraphvizSendMsg!; >> tmpExternHeaderFile.h
						echo _c_!tmpGraphvizSendMsg!_buf !tmpGraphvizSendMsg!; >> !generateBSWCodeSourceFile!
					)

				)^
				else (
					set "tmpGraphvizRowsData="];"
					echo     !tmpGraphvizRowsData! >> !nodeGraphicsFile!

					echo } _c_!tmpGraphvizSendMsg!_msgType; >> !generateBSWCodeHeaderFile!
					echo, >> !generateBSWCodeHeaderFile!

					goto exitOneIsAllLoop
				)
			)
		)

		:exitOneIsAllLoop
			echo, >> !nodeGraphicsFile!
			echo ^} >> !nodeGraphicsFile!

			if exist !nodeGraphicsFile! (

				@REM 
				set "PictureOutputFlg=false"

				for /f %%Z in ( 'set' ) do (
					
					if "!PictureOutputFlg!"=="false" (

						@REM 
						set "tmpData=%%Z"
						if NOT "!tmpData!"=="!tmpData:Graphviz=_!" (
							set "PictureName=%cd%\!onlyNameInputFile!.png"
							@REM 
							if exist !PictureName! ( del !PictureName! )
							dot -Tpng !nodeGraphicsFile! -o !PictureName! 
							
							set "PictureOutputFlg=true"
						)
					)
				)
			)

		type !tmpHearderFile! >> !generateBSWCodeHeaderFile!

		del !tmpHearderFile!

		type tmpExternHeaderFile.h >> !generateBSWCodeHeaderFile!

		del tmpExternHeaderFile.h

		echo, >> !generateBSWCodeHeaderFile!
		echo #endif >> !generateBSWCodeHeaderFile!
	)
	
	@REM 
	set "ConversionSuccessFlg=true"

	@REM 
	goto:eof
@REM ================================================================================================
@REM ====================================   End: Graphviz  ==========================================
@REM ================================================================================================


@REM ================================================================================================
@REM ====================================   Start: DecToHex  ========================================
@REM ================================================================================================

@REM 将十进制数转换为十六进制
:DecToHex

	set "HexCode=0123456789ABCDEF"
	set /a InputNum=%1
	set "HexValue="

	:HexConvloop
	set /a HexModVal=!InputNum!%%16
	call,set HexModVal=!HexCode:~%HexModVal%,1!
	set /a InputNum/=16
	set "HexValue=!HexModVal!!HexValue!"

	if %InputNum% GEQ 10 goto HexConvloop

	@REM 判断输入的数据是否大于16
	if %InputNum% NEQ 0 (
		set "HexValue=0x!InputNum!!HexValue!"
	)^
	else (
		set "HexValue=0x!HexValue!"
	)

	goto:eof

@REM ================================================================================================
@REM ====================================   End: DecToHex  ==========================================
@REM ================================================================================================
