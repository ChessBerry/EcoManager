local score_data

function UpdateScoreData(newData)
	score_data = table.deepcopy(newData)
end

function GetScore()
	return score_data
end
