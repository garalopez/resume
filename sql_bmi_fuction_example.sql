dbo.bmi_calc:

USE [master]
GO
/****** Object:  UserDefinedFunction [dbo].[bmi_calc2]    Script Date: 1/21/2019 10:19:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [dbo].[bmi_calc2](@HEIGHT DECIMAL(14,5) ,@WEIGHT DECIMAL(14,5))

returns VARCHAR(MAX)

begin

declare 
@HEIGHT_METERS DECIMAL(18,4),
@LBSTOKG float,
@WEIGHT_KG INT,
@BMI_HEIGHT DECIMAL(14,6),
@BMI DECIMAL(14,2);

SET @LBSTOKG = '.454';
SET @WEIGHT_KG = @WEIGHT * @LBSTOKG;
SET @HEIGHT_METERS = @HEIGHT * .0254;
SET @BMI_HEIGHT = @HEIGHT_METERS * @HEIGHT_METERS;
SET @BMI = (@WEIGHT * @LBSTOKG) /(@HEIGHT_METERS * @HEIGHT_METERS)

   
return @BMI

end
