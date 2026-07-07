const { generateWebpackConfig } = require('shakapacker')
const webpack = require('webpack')

const safeEnvironmentKeys = [
	'NODE_ENV',
	'RAILS_ENV'
]

const webpackConfig = generateWebpackConfig()

const prunedPlugins = (webpackConfig.plugins || []).filter((plugin) => {
	return !(plugin && plugin.constructor && plugin.constructor.name === 'EnvironmentPlugin')
})

webpackConfig.plugins = [
	...prunedPlugins,
	new webpack.EnvironmentPlugin(
		safeEnvironmentKeys.reduce((acc, key) => {
			acc[key] = process.env[key]
			return acc
		}, {})
	),
	new webpack.ProvidePlugin({
		$: 'jquery',
		jQuery: 'jquery',
		Popper: ['popper.js', 'default']
	})
]

module.exports = webpackConfig
